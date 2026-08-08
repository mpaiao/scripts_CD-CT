#!/bin/bash 
umask 022
#-----------------------------------------------------------------------------#
# !SCRIPT: pre_processing
#
# !DESCRIPTION:
#     Script to prepare boundary and initials conditions for MONAN model.
#     
#     Performs the following tasks:
# 
#        o Creates topography, land use and static variables
#        o Ungrib GFS data
#        o Interpolates to model the grid
#        o Creates initial and boundary conditions
#        o Creates scripts to run the model and post-processing (CR: to be modified to phase 3 and 4)
#        o Integrates the MONAN model ((CR: to be modified to phase 3)
#        o Post-processing (netcdf for grib2, latlon regrid, crop) (CR: to be modified to phase 4)
#
#-----------------------------------------------------------------------------#



#--- Function that shows usage.
function show_usage() {
   echo " Usage: "
   echo ""
   echo " ${0} [-o] [-e EXP ] [-f FCST] [-r RES] [-t YYYYMMDDHH]"
   echo ""
   echo " List of optional flags: "
   echo ""
   echo " -o              -- Overwrite static files."
   echo ""
   echo " List of **required** flags when -c is not set: "
   echo ""
   echo " -e EXP          -- meteorological drivers. For example, GFS"
   echo " -f FCST         -- Simulation length in hours, e.g., 24 or 48."
   echo " -r RES          -- grid resolution. Options are:"
   echo "                    5898242 (~ 10 km)"
   echo "                    2621442 (~ 15 km)"
   echo "                    1024002 (~ 24 km)"
   echo "                    40962   (~ 120 km)"
   echo " -t YYYYMMDDHH   -- Initial time. For example if 22 Sept 2025 00 UTC, set it to:"
   echo "                    2025092200"
   echo ""
}
#---~---


#--- Set environment variables exports:
. setenv.bash
#---~---




#--- Default input variables:
OVERWRITE=true
EXP=""
RES=""
YYYYMMDDHHi=""
FCST=""
#---~---


#--- Parse arguments.
while [[ ${#} > 0 ]]
do
   key="${1}"
   case ${key} in
   -e)
      EXP="${2}"
      shift 2 # past flag and argument
      ;;
   -f)
      FCST="${2}"
      shift 2 # past flag and argument
      ;;
   -o)
      OVERWRITE=true
      shift 1 # past flag
      ;;
   -r)
      RES="${2}"
      shift 2 # past flag and argument
      ;;
   -t)
      YYYYMMDDHHi="${2}"
      shift 2 # past flag and argument
      ;;
   *)
      echo "Unknown key-value argument pair."
      show_usage
      exit 2
      ;;
   esac
done
#---~---



#---~---
#   Make sure all settings were provided.
#---~---
if [[ "${EXP}"         == "" ]] || [[ "${RES}"         == "" ]] ||
   [[ "${YYYYMMDDHHi}" == "" ]] || [[ "${FCST}"        == "" ]]
then
   echo " This script requires some arguments to be set through flags."
   show_usage
   exit 2
fi
#---~---


echo ""
echo "---- Pre Processing ----"
echo ""


#--- Set and create standard directories
DIRHOMES=${DIR_SCRIPTS}/scripts_CD-CT; mkdir -p ${DIRHOMES}    
DIRHOMED=${DIR_DADOS}/scripts_CD-CT;   mkdir -p ${DIRHOMED}  
SCRIPTS=${DIRHOMES}/scripts;           mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;             mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;           mkdir -p ${DATAOUT}
SOURCES=${DIRHOMES}/sources;           mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;               mkdir -p ${EXECS}
#---~---


# Local variables--------------------------------------
# Calculating CIs and final forecast dates in model namelist format:
yyyymmddi=${YYYYMMDDHHi:0:8}
hhi=${YYYYMMDDHHi:8:2}
yyyymmddhhf=$(date +"%Y%m%d%H" -d "${yyyymmddi} ${hhi}:00 ${FCST} hours" )
final_date=${yyyymmddhhf:0:4}-${yyyymmddhhf:4:2}-${yyyymmddhhf:6:2}_${yyyymmddhhf:8:2}.00.00
export DIRRUN=${DIRHOMED}/run.${YYYYMMDDHHi}; rm -fr ${DIRRUN}; mkdir -p ${DIRRUN}
#-------------------------------------------------------



echo -e  "${GREEN}==>${NC} Scripts_CD-CT last commit: \n"
git log | head -1


if [[ ! -d ${DATAIN}/fixed ]]
then
	echo -e  "${GREEN}==>${NC} copying and linking fixed input data ${SYSTEM_KEYC}... \n"
	mkdir -p ${DATAIN}
	rsync -rv --chmod=ugo=rw ${DIRDADOS}/MONAN_datain/datain/fixed ${DATAIN}
	rsync -rv --chmod=ugo=rwx ${DIRDADOS}/MONAN_datain/execs ${DIRHOMED}
	ln -sf ${DIRDADOS}/MONAN_datain/datain/WPS_GEOG ${DATAIN}
fi


<<<<<<< HEAD
# Building MP_THOMPSON DBL tables
echo ""
echo -e  "${GREEN}==>${NC} Building MP_THOMPSON DBL tables ...\n"

files_needed=("${DATAIN}/fixed/MP_THOMPSON_QRacrQG_DATA.DBL" "${DATAIN}/fixed/MP_THOMPSON_QRacrQS_DATA.DBL" "${DATAIN}/fixed/MP_THOMPSON_freezeH2O_DATA.DBL" "${DATAIN}/fixed/MP_THOMPSON_QIautQS_DATA.DBL")

if [[ ! -s ${DATAIN}/fixed/MP_THOMPSON_QRacrQG_DATA.DBL   ]] ||
   [[ ! -s ${DATAIN}/fixed/MP_THOMPSON_QRacrQS_DATA.DBL   ]] ||
   [[ ! -s ${DATAIN}/fixed/MP_THOMPSON_freezeH2O_DATA.DBL ]] ||
   [[ ! -s ${DATAIN}/fixed/MP_THOMPSON_QIautQS_DATA.DBL   ]]
then
   echo -e  "${GREEN}==>${NC} This calculation can take about 2 minutes on a supercomputer...\n"

   rm -f ${EXECS}/MP_THOMPSON_*_DATA.DBL
   rm -f ${DATAIN}/fixed/MP_THOMPSON_*_DATA.DBL

   cd ${EXECS}
   ${EXECS}/build_tables

   mv ${EXECS}/MP_THOMPSON_QRacrQG_DATA.DBL    ${DATAIN}/fixed
   mv ${EXECS}/MP_THOMPSON_QRacrQS_DATA.DBL    ${DATAIN}/fixed
   mv ${EXECS}/MP_THOMPSON_freezeH2O_DATA.DBL  ${DATAIN}/fixed
   mv ${EXECS}/MP_THOMPSON_QIautQS_DATA.DBL    ${DATAIN}/fixed

   chmod 755 ${DATAIN}/fixed/MP_THOMPSON_*_DATA.DBL
   chgrp $USER ${DATAIN}/fixed/MP_THOMPSON_*_DATA.DBL

   # verify here if the tables were created 
   for file in "${files_needed[@]}"
   do
     if [[ -s "${file}" ]]
     then
       echo ""
       echo -e "${GREEN}==>${NC} File ${file} generated sucessfully in ${EXECS} and moved to ${DATAIN}/fixed!"
       echo
     else
       echo -e  "\n${RED}==>${NC} ***** WARNING *****\n"   
       echo -e  "${RED}==>${NC} [${0}] An error occurred during MP_THOMPSON build_tables. At least the file ${file} was not generated. \n"
       exit -1
     fi
   done
else
   echo -e "${GREEN}==>${NC} MP_THOMPSON DBL tables already exist in ${DATAIN}/fixed!"
fi


# Copying NoahmpTable.TBL from source to datain folder
echo ""
echo -e "${GREEN}==>${NC} Copying NoahmpTable.TBL from source code to datain fixed folder ...\n"

if ${OVERWRITE} || [[ ! -s ${DATAIN}/fixed/NoahmpTable.TBL ]]
then
   if [[ -s ${MONANDIR}/src/core_atmosphere/physics/physics_noahmp/parameters/NoahmpTable.TBL ]]
   then
      cp -f ${MONANDIR}/src/core_atmosphere/physics/physics_noahmp/parameters/NoahmpTable.TBL ${DATAIN}/fixed
      chmod 755 ${DATAIN}/fixed/NoahmpTable.TBL
   else
      echo -e "${RED}==>${NC} File NoahmpTable.TBL not found in ${MONANDIR}. Please run script 1.install_monan.bash first. \n"
      exit -1
   fi
else
   echo -e "${GREEN}==>${NC} File NoahmpTable.TBL already exist in ${DATAIN}/fixed.\n"
fi

#TODO: EGK - Verify if necessary data for NOAH-MP soil colour pre-processing is present in datain folder
echo -e "${GREEN}==>${NC} Verifying whether clm_soilcolour_21class_30s exists in datain WPS_GEOG folder for running NOAH-MP model with MONAN soil colour table activated ...\n"

if [[ ! -d ${DATAIN}/WPS_GEOG/clm_soilcolour_21class_30s/ ]]
then
   mkdir -p ${DATAIN}/WPS_GEOG
   cd ${DATAIN}/WPS_GEOG
   echo -e "${GREEN}==>${NC} Downloading clm_soilcolour_21class_30s/ folder...\n"
# needs to download data from MONAN dataserver or some mirror... 
#   rm -f ${DATAIN}/WPS_GEOG/wget-log*
#   wget https://...
#   ln -sf ${DIRDADOS}/MONAN_datain/datain/WPS_GEOG/clm_soilcolour_21class_30s ${DATAIN}/WPS_GEOG
else
   echo -e "${GREEN}==>${NC} Folder clm_soilcolour_21class_30s already exists in ${DATAIN}/WPS_GEOG.\n"
fi


# Move back to scripts folder
cd ${SCRIPTS}


#---~---
#   Create the x1.${RES}.static.nc file. This is normally needed only once, when the file
# does not exist. However, if the files must be recreated for whichever reason, option 
# OVERWRITE forces creation.
#---~---
if ${OVERWRITE} || [[ ! -s ${DATAIN}/fixed/x1.${RES}.static.nc ]]
then
   echo -e "${GREEN}==>${NC} Creating static.bash for submiting init_atmosphere to create x1.${RES}.static.nc...\n"
   time ./make_static.bash -e ${EXP} -f ${FCST} -r ${RES} -t ${YYYYMMDDHHi}
else
   echo -e "${GREEN}==>${NC} File x1.${RES}.static.nc already exist in ${DATAIN}/fixed.\n"
fi
#---~---


#--- Run the degrib step.
echo -e  "${GREEN}==>${NC} Submitting Degrib...\n"
time ./make_degrib.bash -e ${EXP} -f ${FCST} -r ${RES} -t ${YYYYMMDDHHi}
#---~---


#--- Run the atmosphere initialisation step.
echo -e  "${GREEN}==>${NC} Submitting Init Atmosphere...\n"
time ./make_initatmos.bash -e ${EXP} -f ${FCST} -r ${RES} -t ${YYYYMMDDHHi}
#---~---




