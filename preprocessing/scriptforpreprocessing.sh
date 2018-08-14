#   The dependencies for this script are
#	1. AFNI
#	2. DCM2NII
#	3. FSL (for some bits an pieces though not must)

# This script required some organzining of the data which was performed 
# by the neuro-radiology team invovled and is hence dependent on that folder structure
# Basically each subject contains two (CET1 as well as FLAIR) *_SOURCE and two *_SEG folders.



#Adding AFNI tools to path
export PATH=$PATH:/usr/lib/afni/bin

cd /home/brain/host/NIFTI_files
dest_folder='/home/brain/host/NIFTI_files_v3';
mkdir $dest_folder
for f in */; do 
	echo $f; 
	cd $f;
		#c=0
		mkdir "$dest_folder"/"$f" 
		for e in *SOURCE/; do
			#ae=${e//[[:blank:]]/}
			#ae=`echo $ae | tr --delete $/`
			otp="$dest_folder"/"$f""$e"
			mkdir $otp
			#echo $ae; 
			cd "$e";
			#pwd;
			#dcm2nii `ls | head -n 1`;
			# rm *_BRAIN.nii.gz
			op=`find . -name '*.nii.gz' | head -n 1`;
			match=".nii.gz";			
			op2="${op%%${match}*}_BRAIN${match}${op##*${match}}"

			3dUnifize -prefix anatT1_U -input $op
    		3dSkullStrip -input anatT1_U+orig -prefix anatT1_US -niter 400 -ld 40
    		
    		3dAFNItoNIFTI -prefix $op2 anatT1_US+orig

    		#3dresample -dxyz 1.0 1.0 1.0 -prefix 111.dset -input anatT1_US+orig
			#fsl5.0-bet $op $op2

			mv `find . -name '*.nii.gz'` $otp

			
			3dAllineate -base $template -source *_CET1_BRAIN.nii.gz \
            -prefix CET1_Allineate_template.nii -1Dmatrix_save CET1_Allineate_template \
            -cmass -final wsinc5 -float -master BASE -twobest 7 -fineblur 4.44
			3dQwarp -prefix CET1.nii -blur 0 3 -maxlev 1 \
		             -base $template -source CET1_Allineate_template.nii            
			3dAllineate -input *_CET1_SEG.nii.gz -master CET1.nii -prefix check_allin_seg.nii \
					-1Dmatrix_apply CET1_Allineate_template.aff12.1D -overwrite
			3dNwarpApply -nwarp CET1_WARP.nii -source check_allin_seg.nii -prefix mask.nii -overwrite
			3dcalc -a mask.nii -expr 'ispositive(a-0.1)' -prefix CET1_SEG.nii


			3dAllineate -base $template -source *_FLAIR_BRAIN.nii.gz \
		            -prefix FLAIR_Allineate_template.nii -1Dmatrix_save FLAIR_Allineate_template \
		            -cmass -final wsinc5 -float -master BASE -twobest 7 -fineblur 4.44
			3dQwarp -prefix FLAIR.nii -blur 0 3 -maxlev 1 \
		             -base $template -source FLAIR_Allineate_template.nii            
			3dAllineate -input *_FLAIR_SEG.nii.gz -master FLAIR.nii -prefix check_allin_seg.nii \
					-1Dmatrix_apply FLAIR_Allineate_template.aff12.1D -overwrite
			3dNwarpApply -nwarp FLAIR_WARP.nii -source check_allin_seg.nii -prefix mask.nii -overwrite
			3dcalc -a mask.nii -expr 'ispositive(a-0.1)' -prefix FLAIR_SEG.nii
			3dcalc -a FLAIR_SEG.nii -b CET1_SEG.nii -expr 'extreme(a,b)' -prefix "$f"_seg.nii

			mv CET1.nii "$f"_t1ce.nii
			mv FLAIR.nii "$f"_flair.nii
 			#c=$((c+1))
			cd ..  
		done;
		#echo $c
		#c=0
		for e in *SEG/; do
			#ae=${e//[[:blank:]]/}
			#ae=`echo $ae | tr --delete $/`			
			otp="$dest_folder"/"$f""$e"
			mkdir $otp			
			#echo $ae; 
			cd "$e";
			#pwd;
			#dcm2nii `ls | head -n 1`;
			mv `find . -name '*.nii.gz'` $otp
			cd .. 
			#c=$((c+1)) 
			
		done;
	 	#echo $c
		
	cd .. 
done