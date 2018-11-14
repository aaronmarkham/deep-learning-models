# Copyright 2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# Ensure you have Horovod, OpenMPI, and Tensorflow installed on each machine
# Specify hosts in the file `hosts`

# Below was tested on DLAMI v17 Ubuntu.
# If you are using AmazonLinux change ens3 in line 23 to eth0
# If you have version 12 or older, you need to remove line 23 below.
set -ex
if [ -z "$1" ]
  then
    gpus=8
  else
    gpus=$1
    echo "User is asking to run $gpus GPUs!"
fi
source activate tensorflow_p36
cd ..
/home/ubuntu/anaconda3/envs/tensorflow_p36/bin/mpirun -np $gpus -mca plm_rsh_no_tree_spawn 1 \
        -bind-to socket -map-by slot \
        -x HOROVOD_HIERARCHICAL_ALLREDUCE=1 -x HOROVOD_FUSION_THRESHOLD=16777216 \
        -x NCCL_MIN_NRINGS=4 -x LD_LIBRARY_PATH -x PATH -mca pml ob1 -mca btl ^openib \
        -x NCCL_SOCKET_IFNAME=ens3 -mca btl_tcp_if_exclude lo,docker0 \
        python -W ignore ~/deep-learning-models/models/resnet/tensorflow/train_imagenet_resnet_hvd.py \
        --model resnet50 --fp16 --adv_bn_init \
        --display_every 100 --lr 6.4 --loss_scale 1024. --lr_decay_mode poly \
        --synthetic --log_dir ~/resnet50_log --num_batches 1000
