cd terraform

template=../hosts.tmpl
hostfile=../hosts
hosts="$(terraform output --json)"
cp $template $hostfile
masterip=$(echo $hosts | jq -r '.ip.value[0]')
line="master ansible_host=$masterip ansible_user=root"
sed -i "/\[master\]/a $line" $hostfile

# for((no=1;no<=$workernodes;no++))
# do
#     workerip=$(echo $hosts | jq -r --arg no "$no" ".worker_${no}_ip.value")
#     line="worker${no} ansible_host=$workerip ansible_user=root"
#     sed -i "/\[workers\]/a $line" $hostfile
# done

cd ..
mv hosts ./ansible/hosts