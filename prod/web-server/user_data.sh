#!/bin/bash
sudo yum install -y aws-cli
aws configure set region ${region}
curl -o ${cloudwatch_script_path} ${your_script_url}
chmod +x ${cloudwatch_script_path}
(crontab -l 2>/dev/null; echo "*/5 * * * * ${cloudwatch_script_path}") | crontab -
