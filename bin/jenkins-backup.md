# Archive Jenkins settings and plugins
https://github.com/sue445/jenkins-backup-script

* `$JENKINS_HOME/*.xml`
* `$JENKINS_HOME/jobs/*/*.xml`
* `$JENKINS_HOME/nodes/*`
* `$JENKINS_HOME/plugins/*.jpi`
* `$JENKINS_HOME/secrets/*`
* `$JENKINS_HOME/users/*`

# Usage
```sh
./jenkins-backup.sh /path/to/jenkins_home archive.tar.gz

# add timestamp suffix
./jenkins-backup.sh /path/to/jenkins_home backup_`date +"%Y%m%d%H%M%S"`.tar.gz
```

## Backup commands
```bash
./jenkins-backup.sh $JENKINS_HOME /path/to/backup_`date +"%Y%m%d%H%M%S"`.tar.gz
```

## Restore commands
example

```bash
sudo /etc/init.d/jenkins stop
cd /path/to/backup_dir
tar xzvf backup.tar.gz
sudo cp -R jenkins-backup/* /path/to/jenkins/
sudo chown jenkins:jenkins -R /path/to/jenkins/
sudo /etc/init.d/jenkins start
```
