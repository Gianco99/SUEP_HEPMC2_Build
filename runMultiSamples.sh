#!/bin/bash

# Define the Docker image and the paths
docker_image="suep-generator"
input_file="decay_darkphoton_hadronic.cmnd"
output_dir="/afs/cern.ch/user/g/gdecastr/SUEP_HEPMC2_Build/output"
eos_dir="root://eosuser.cern.ch//eos/user/g/gdecastr/SUEPCoffea_dask/SUEP_Samples/Docker/Hadronic_3_3"

# Number of runs
num_runs=50
events=2000

# Loop to generate the random seeds and run the Docker container
for ((i=1; i<=num_runs; i++)); do
  # Generate a random seed
  random_seed=$RANDOM
  
  # Define the output file name with the random seed
  output_file="ZH_test_${random_seed}.hepmc"
  
  # Run the Docker command
  docker run --rm -v ${output_dir}:/app/output -it ${docker_image} 125.0 3.0 3.0 ${input_file} /app/output/${output_file} 32 ${events}
  
  # Copy the output to EOS with the random seed in the file name
  xrdcp -f ${output_dir}/${output_file} ${eos_dir}/${output_file}
  rm -rf ${output_dir}/${output_file}
done
