

cd /data/ddn/Congo
find $(pwd) -name "*TRE*.tif.gz" | parallel -j 24 --bar "gzip -dc {} > TRE_uncompressed/{/.}"


### Congo Mosaic

# Rough bounding rectangle around Congo
mbrminx=6.4875074606426
mbrmaxy=5.82675640853353
mbrmaxx=33.3019150169375
mbrminy=-12.239581581588
bbox="$mbrminx $mbrmaxy $mbrmaxx $mbrminy"

# Annual mosaics
## Mosaic global 166 tiles for each of 13 years

# Make years data driven by what is in the directory.
YEARS=$(ls *_TRE.*.tif | sort | cut -d "." -f 2 | uniq)
for YEAR in ${YEARS}; do
    if [[ -f  VCF_global_${YEAR}.vrt ]] 
        then
            echo "Skipping VCF_global_${YEAR}.vrt, we already made it."
        else
            gdalbuildvrt VCF_global_${YEAR}.vrt *_TRE.${YEAR}*.tif;
    fi
    #gdal_translate -co COMPRESS=LZW -projwin $bbox VCF_global_${YEAR}.vrt VCF_congo_${YEAR}.tif
    gdal_translate -co COMPRESS=LZW VCF_global_${YEAR}.vrt VCF_global_${YEAR}.tif

done


for i in *congo*.tif; do r.in.gdal $i out=${i/.tif/}; done
for i in $(g.mlist rast pat=VCF_congo*); do r.mapcalc ${i}="if(${i} > 100, 0, float(${i})/100)"; done

g.region align=VCF_congo_2000
r.series input=$(g.mlist rast pat=VCF_congo_* sep=,) output=VCF_slope_2000_2010,VCF_slope_2000_2010_R2 method=slope,detcoeff
r.series input=$(echo VCF_congo_{2007..2010} | sed 's/ /,/g') output=VCF_slope_2007_2010,VCF_slope_2007_2010_R2 method=slope,detcoeff

r.series input=$(g.mlist rast pat=VCF_congo_* sep=,) output=VCF_R2_2000_2010 method=detcoeff

for i in $(g.mlist rast pat=VCF_slope*); do r.out.gdal input=$i output=$i.tif create=COMPRESS=LZW; done

### Difference analysis with PALSAR
g.region rast=VCF_congo_2008

r.resamp.stats --o input=FNF_${YEAR}_bin output=fnf_to_vcf_grid_pct method=average
r.mapcalc diff_forest_vcf="VCF_congo_2008 - fnf_to_vcf_grid_pct"
r.out.rast input=diff_forest_vcf output=VCF_FNF_2008_difference


