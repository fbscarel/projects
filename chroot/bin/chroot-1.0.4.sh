#!/bin/bash
# chroot-1.0.4.sh, 2014/08/21 09:44:35 fbscarel $

# misc variables
VHOST_PREFIX="vhost"
PASSWORD_LENGTH=12
RC_MOUNT="/etc/rc.mount-vhosts"
ABS_PATH=`readlink -f $0 | sed 's/\/[^\/]*$//'`
MINI_SENDMAIL_PATH="$ABS_PATH/mini_sendmail/mini_sendmail"

# database variables
MYSQL_DIR="/var/run/mysqld"
POSTGRES_DIR="/var/run/postgresql"
POSTGRES_USER="postgres"

# webserver variables
DOCROOT="/var/www"
WWW_USER="www-data"
NGINX_HOME="/etc/nginx"
NGINX_AVAILABLE="sites-available"
NGINX_ENABLE="sites-enabled"
PHPFPM_HOME="/etc/php5/fpm"
PHPFPM_ENABLE="pool.d"
PHPFPM_INIT="/etc/init.d/php5-fpm"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# skip slashes in strings for 'sed' substitution
skipslashes() {
  echo $1 | sed 's/\//\\\//g'
}

# check if module is running standalone
check_standalone() {
  if [ $1 ]; then
    usage
  fi
}

# check if supplied filename exists
check_file() {
  if [ ! -f "$1" ]; then
    echo "  [!] File $1 does not exist!"
    check_standalone $tstand
    return 1
  fi
}

# check if supplied user exists
check_user() {
  [ $( getent passwd | egrep -c "^$1" ) -eq 0 ] && return 0 || return 1
}

# run autoconfiguration for nginx and PHP-FPM
run_autoconf() {
  # are we running standalone?
  if [ $tstand ]; then
    echo "  [*] Starting webserver autoconfiguration module"
  else
    echo "  [*] Attempting webserver autoconfiguration"
  fi

  # set template filenames
  nginx_template="$NGINX_HOME/$NGINX_AVAILABLE/$template"
  phpfpm_template="$PHPFPM_HOME/$PHPFPM_ENABLE/$template.conf"

  # set new filenames
  nginx_newfile="$NGINX_HOME/$NGINX_AVAILABLE/$name"
  phpfpm_newfile="$PHPFPM_HOME/$PHPFPM_ENABLE/$name.conf"

  # check if template file was supplied
  if [ -z "$template" ]; then
    echo "  [!] You must specify a configuration template to be used with the '-t' option!"
    check_standalone $tstand
    return 1
  fi

  # check if templates exist
  check_file "$nginx_template"
  check_file "$phpfpm_template"

  # check if hostnames were provided
  if [ -z "$oldhost" ] || [ -z "$newhost" ]; then
    echo "  [!] Hostnames were not provided, can't autoconfigure!"
    check_standalone $tstand
    return 1
  fi

  # copy and symlink templates
  echo "  [*] Copying configuration files"
  cp -a $nginx_template $nginx_newfile
  cd $NGINX_HOME/$NGINX_ENABLE ; ln -sf ../$NGINX_AVAILABLE/$name .
  cp -a $phpfpm_template $phpfpm_newfile

  # substitute strings inline
  echo "  [*] Updating configuration files"
  sed -i "s/$oldhost/$newhost/g" $nginx_newfile
  sed -i "s/$template/$name/g" $nginx_newfile
  sed -i "s/$oldhost/$newhost/g" $phpfpm_newfile
  sed -i "s/$template/$name/g" $phpfpm_newfile

  echo "  [*] Configuration files $nginx_newfile and $phpfpm_newfile created successfully!"
  echo "  [*] Please double-check these files and verify everything is correct. Remember nginx accepts only ONE 'default_server' virtualhost."
  echo -n "  [*] If all is well, simply restart nginx and PHP-FPM to have your site online."

  # if standalone, exit now
  if [ $tstand ]; then
    echo " See ya next time!"
    exit 0
  else
    echo -ne "\n"
  fi
}

# set php-fpm running user
set_privs() {
  echo "  [*] Starting PHP-FPM privilege configuration module"

  # check if php-fpm init script exists, set php-fpm pool filename
  check_file "$PHPFPM_INIT"
  phpfpm_file="$PHPFPM_HOME/$PHPFPM_ENABLE/$name.conf"

  # check if supplied filename exists, replace user accordingly
  check_file "$phpfpm_file"
  for param in user group; do
    sed -i "s/^\($param = \).*/\1$1/" $phpfpm_file
  done

  # everything OK, exit gracefully
  echo "  [*] PHP-FPM pool $name configured to run as $1 successfully. Restarting php-fpm..."
  $PHPFPM_INIT restart
  exit 0
}

# set permissions for chroot
set_perms() {
  # are we running standalone?
  if [ $cflag ]; then
    echo "  [*] Starting permission configuration module"
  else
    echo "  [*] Configuring directory permissions"
  fi

  # check if folder exists, who knows...
  if [ ! -d "$topdir" ]; then
    echo "  [!] Folder $topdir does not exist! Are you sure this virtualhost has been created before?"
    check_standalone $cflag
    return 1
  fi

  echo "  [*] We're setting SITE-WIDE read-only permissions, you may have to set (some) folders with writable permissions manually afterwards"

  # set /tmp perms
  chmod 1777 $topdir/tmp

  # set default dir perms
  chown    $fullname:$fullname $topdir
  chown -R $fullname:$fullname $topdir/htdocs/
  chmod 550 $topdir $topdir/htdocs/

  # set baseline permissions (alter later for +w dirs)
  find $topdir/htdocs -type f -exec chmod 440 {} \;
  find $topdir/htdocs -type d -exec chmod 550 {} \;

  ## set specific permissions to files/folders for various software packages here
  #

  # detect & set permissions for Joomla installation
  checkfile="$topdir/htdocs/README.txt"
  if [ -f "$checkfile" ] && [ $(grep -c "Joomla" $checkfile) -ne 0 ]; then
    echo "  [*] Joomla installation detected. Setting Joomla-specific permissions..."

    # set +w on 'images/' and its files/subfolders
    chmod 750 $topdir/htdocs/images
    find $topdir/htdocs/images -type f -exec chmod 640 {} \;
    find $topdir/htdocs/images -type d -exec chmod 750 {} \;
  fi

  echo -n "  [*] Folder permissions set successfully on $topdir."

  # if standalone, exit now
  if [ $cflag ]; then
    echo " See ya next time!"
    exit 0
  else
    echo -ne "\n"
  fi
}

# load database dumps
load_db() {
  echo "  [*] Starting database load module"

  # check if dumpfile was supplied
  if [ -z "$dumpfile" ]; then
    echo "  [!] You must specify a SQL dumpfile to be used with the '-l' option!"
    usage
  elif [ ! -f "$dumpfile" ]; then
    echo "  [!] Dumpfile $dumpfile does not exist!"
    usage
  fi

  # check if DBMS type was specified
  if [ -z "$db" ]; then
    echo "  [!] You must specify which DBMS (MySQL or PostgreSQL) will be used with the '-d' option!"
    usage
  fi

  # check if DB connection username was supplied
  if [ -z "$dbuser" ] && [ "$db" != "P" ]; then
    echo "  [!] You must specify a username for DB connection with the '-u' option!"
    usage
  fi

  # double-check DB connection password, if left blank
  if [ -z "$dbpass" ] && [ "$db" != "P" ]; then
    echo "  [!] No password for database connection was specified (using the '-p' option)."
    echo -n "  [!] Press ENTER if you're OK with that, else CTRL+C and correct parameters >> "
    echo
    read
  fi

  # set DB name, username and password
  dbname="${VHOST_PREFIX}_${name}"
  newdbuser=$dbname
  newdbpass=`tr -cd '[:alnum:]' < /dev/urandom | fold -w$PASSWORD_LENGTH | head -n1`

  # load dumpfile on MySQL
  if [ "$db" == "M" ]; then
    # check if we have login privileges
    echo -n "  [*] Checking login privileges: "
    retval=`mysql -u $dbuser -p$dbpass -e "select @@version"`

    if [ "$?" -ne 0 ]; then
      echo "  [!] Can't login to MySQL as user $dbuser using password $dbpass."
      echo
      echo "  [!] Please correct any problems and re-run the script. Terminating."
      exit 1
    else
      echo "OK!"
    fi

    # check if DB exists
    echo -n "  [*] Checking if database $dbname exists: "
    retval=`mysql -u $dbuser -p$dbpass $dbname -e "select @@version;"`

    # if it doesn't, create it right now with new user/pass combination
    if [ "$?" -ne 0 ]; then
      # check user privileges
      retval=`mysql -u $dbuser -p$dbpass -e "SHOW GRANTS FOR $dbuser@localhost" | grep -ie "GRANT ALL PRIVILEGES ON *.*"`

      if [ "$?" -ne 0 ]; then
        echo "  [!] User $dbuser@localhost doesn't have enough privileges to create databases!"
        echo
        echo "  [!] Please correct any problems and re-run the script. Terminating."
        exit 1
      fi

      # we do have privileges, let's create the DB
      mysql -u $dbuser -p$dbpass -e "CREATE DATABASE $dbname;"
      mysql -u $dbuser -p$dbpass -e "GRANT ALL PRIVILEGES ON $dbname.* TO $newdbuser@localhost IDENTIFIED BY \"$newdbpass\";"
      echo "  [*] Created new database $dbname with user '$newdbuser' and password '$newdbpass'."
      echo "  [*] Update your website accordingly."
    else
      echo "It does!"
    fi

    echo "  [*] Populating database $dbname with dumpfile $dumpfile"
    if [ -z "$dbpass" ]; then
      dbret=`mysql -u $dbuser $dbname < $dumpfile 1> /dev/null`
    else
      dbret=`mysql -u $dbuser -p$dbpass $dbname < $dumpfile 1> /dev/null`
    fi

  # load dumpfile on PostgreSQL
  elif [ "$db" == "P" ]; then
    # chdir to avoid 'permission denied' errors using sudo
    cd /tmp

    # check user privileges
    echo -n "  [*] Checking if we have privileges over user '$POSTGRES_USER': "
    retval=`sudo -nu $POSTGRES_USER id`

    if [ "$?" -ne 0 ]; then
      echo "  [!] We don't have privileges to sudo as user '$POSTGRES_USER'!."
      echo
      echo "  [!] Please correct any problems and re-run the script. Terminating."
      exit 1
    else
      echo " We do!"
    fi

    # check if dumpfile user matches $newdbuser
    dumpuser=`grep "OWNER TO" $dumpfile | sed 's/.* //' | cut -d';' -f1 | uniq`

    if [ "$dumpuser" != "$newdbuser" ]; then
      echo "  [*] Fixing table owners on dumpfile $dumpfile"
      sed -i "s/OWNER TO $dumpuser/OWNER TO $newdbuser/" $dumpfile
      sed -i "s/Owner\: $dumpuser/Owner\: $newdbuser/" $dumpfile
    fi

    # check if DB exists
    echo -n "  [*] Checking if database $dbname exists: "
    retval=`sudo -u $POSTGRES_USER psql $dbname -c "SHOW SERVER_VERSION;"`

    # if it doesn't, create it right now with new user/pass combination
    if [ "$?" -ne 0 ]; then
      sudo -u $POSTGRES_USER psql -c "CREATE DATABASE $dbname;" -o /dev/null
      sudo -u $POSTGRES_USER psql -c "CREATE USER $newdbuser WITH PASSWORD '$newdbpass';" -o /dev/null
      sudo -u $POSTGRES_USER psql -c "GRANT ALL PRIVILEGES ON DATABASE $dbname TO $newdbuser;" -o /dev/null

      echo "  [*] Created new database $dbname with user '$newdbuser' and password '$newdbpass'."
      echo "  [*] Update your website accordingly."
    else
      echo "It does!"
    fi

    echo "  [*] Populating database $dbname with dumpfile $dumpfile"
    dbret=`sudo -u $POSTGRES_USER psql $dbname < $dumpfile 1> /dev/null`
  fi

  # check if any errors occurred on the previous step, exit on the spot
  if [ -n "$dbret" ]; then
    echo "  [!] Something went wrong while loading dumpfile $dumpfile. The error is shown below:"
    echo "  [!] $dbret"
    echo
    echo "  [!] Please correct any problems and re-run the script. Terminating."
    exit 1
  fi

  # everything OK, exit gracefully
  echo "  [*] Dumpfile $dumpfile loaded successfully on database $dbname!"
  echo "  [*] Please re-run the script without the '-l' option if the chroot has not been created yet. See ya next time!"
  exit 0
}

# show program usage and exit
usage() {
  echo "Usage: $0 -n VHOST_NAME [-c] [-d (M)ySQL|(P)ostgreSQL] [-l DUMPFILE] [-p PASSWORD]" 1>&2
  echo "                                       [-s USER] [-t TEMPLATE] [-u USERNAME] [-w WEBDIR]"
  echo "                                       [-y OLDHOST] [-z NEWHOST]"
  echo "Create a chroot environment under "$DOCROOT/VHOST_NAME", ready for deployment"
  echo "using nginx/PHP-FPM. Can also be used to set chroot permissions, load database dumps,"
  echo "load website content, set PHP-FPM running privileges and write nginx/PHP-FPM configuration"
  echo "files automatically."
  echo
  echo "Available options:"
  echo "  -c          Set permissions for the chroot directory. Takes no parameters, exits after"
  echo "              completion."
  echo "  -d          Specify a (M)ySQL or (P)ostgreSQL connection for socket directory"
  echo "              creation/mounting under 'var/run' inside the chroot or database creation"
  echo "              using the '-l' option. Can be left blank if database connection will be"
  echo "              done via TCP/IP or no connection is needed."
  echo "  -h          Show this help screen."
  echo "  -l          Load DUMPFILE to the database VHOST_NAME using a MySQL or PostgreSQL"
  echo "              connection specified with the '-d' option. Check also '-u' and '-p'"
  echo "              options. Exits after completion."
  echo "  -n          Directory name of the virtualhost chroot and/or database to be created"
  echo "              or configured. Mandatory in all cases."
  echo "  -p          Password to use when connecting to the database. Optional when using"
  echo "              MySQL, not needed when using PostgreSQL."
  echo "  -s          Set PHP-FPM pool VHOST_NAME to run as USER. USER must exist in /etc/passwd,"
  echo "              NIS or LDAP authentication databases. Exits after completion."
  echo "  -t          Use TEMPLATE as a sample configuration file to be used for nginx/PHP-FPM"
  echo "              autoconfiguration. Writes new configuration files to $NGINX_HOME/$NGINX_AVAILABLE"
  echo "              symlinking to $NGINX_HOME/$NGINX_ENABLE and to $PHPFPM_HOME/$PHPFPM_ENABLE."
  echo "  -u          Username to use when connecting to the database. Mandatory when using"
  echo "              MySQL, not needed when using PostgreSQL."
  echo "  -w          Directory, .tar.gz or .tar.bz2 file containing the website content to"
  echo "              be deployed to the 'htdocs/' directory inside the chroot."
  echo "  -y          OLD hostname used on TEMPLATE, for string substitution. Use only with the '-t'"
  echo "              option. Mandatory with '-t' option."
  echo "  -z          NEW hostname to be used on nginx/PHP-FPM configuration files. Use only with the"
  echo "              '-t' option. Mandatory with '-t' option."
  exit 1
}

# check if we're running as root
myid=`id -u`
if [ "$myid" -ne 0 ]; then
  echo "  [!] This script must be run as root, terminating."
  exit 1
fi

# save current directory
mydir=`pwd`

# check commandline parameters
while getopts ":n:cd:hl:p:s:t:u:w:y:z:" opt; do
    case "$opt" in
        c)
            cflag=true
            ;;
        d)
            dflag=true
            db=${OPTARG}
            ;;
        h)
            usage
            ;;
        l)
            dumpfile=${OPTARG}
            lflag=true

            # check if dumpfile was passed using relative/absolute path
            fchar=`echo $dumpfile | head -c1`
            if [ ! "$fchar" == "/" ]; then
              dumpfile="$mydir/$dumpfile"
            fi
            ;;
        n)
            name=${OPTARG}

            fullname="$VHOST_PREFIX-$name"
            topdir="$DOCROOT/$name"
            ;;
        p)
            dbpass=${OPTARG}
            ;;
        s)
            privuser=${OPTARG}
            ;;
        t)
            tflag=true
            template=${OPTARG}
            ;;
        u)
            dbuser=${OPTARG}
            ;;
        w)
            webdir=${OPTARG}

            # check if webdir was passed using relative/absolute path
            fchar=`echo $webdir | head -c1`
            if [ ! "$fchar" == "/" ]; then
              webdir="$mydir/$webdir"
            fi
            ;;
        y)
            oldhost=${OPTARG}
            ;;
        z)
            newhost=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

# 'name' is mandatory
if [ -z "$name" ]; then
  echo "  [!] Option '-n' is mandatory!"
  usage
fi

# check if we're only configuring privileges
if [ ! -z $privuser ]; then
  if [ ! $( check_user $privuser ) ]; then
    echo "  [!] User $privuser does not exist!"
    usage
  fi
  set_privs $privuser
fi

# check DBMS type
if [ "$db" != "M" ] && [ "$db" != "P" ] && [ $dflag ]; then
  echo "  [!] Invalid DBMS type specified! Use either (M) for MySQL or (P) for PostgreSQL."
  usage
fi

# check if we're only setting perms
if [ $cflag ]; then
  set_perms
fi

# check if we're running the load_db module only
if [ $lflag ]; then
  load_db
fi

# double-check that the user really intends for no DB socket to be created
if [ -z "$db" ]; then
  echo "  [!] No database connection was selected!"
  echo -n "  [!] Press ENTER if you're OK with that, else CTRL+C and correct parameters >> "
  echo
  read
fi

# check if vhost chroot directory already exists
if [ -d $topdir ]; then
  # maybe we're just running the autoconfiguration module?
  if [ $tflag ]; then
    tstand=true
    run_autoconf
  fi

  echo "  [!] Error: Directory \"$topdir\" already exists, terminating"
  exit 1
fi

echo "  [*] Using $DOCROOT as document root"

# make dirs
echo "  [*] Creating chroot directory structure"
mkdir -p $topdir/{bin,etc,htdocs,lib,lib64,tmp,usr}
mkdir -p $topdir/lib/x86_64-linux-gnu
mkdir -p $topdir/usr/lib/x86_64-linux-gnu
mkdir -p $topdir/usr/share
mkdir -p $topdir/usr/sbin

# make dirs for MySQL/PostgreSQL socket hardlink
if [ "$db" == "M" ]; then
  mkdir -p $topdir/$MYSQL_DIR
elif [ "$db" == "P" ]; then
  mkdir -p $topdir/$POSTGRES_DIR
fi

echo "  [*] Copying files necessary for chroot operation"

# copy configuration files from /etc
cp -a /etc/hosts          $topdir/etc/
cp -a /etc/ld.so.cache    $topdir/etc/
cp -a /etc/localtime      $topdir/etc/
cp -a /etc/nsswitch.conf  $topdir/etc/
cp -a /etc/resolv.conf    $topdir/etc/

# copy timezone information
cp -a /usr/share/zoneinfo/  $topdir/usr/share/

# copy libs, dereferencing symlinks
cp -L /lib64/ld-linux-x86-64.so.2                   $topdir/lib64/ld-linux-x86-64.so.2
cp -L /lib/snoopy.so                                $topdir/lib/snoopy.so
cp -L /lib/x86_64-linux-gnu/libbz2.so.1.0           $topdir/lib/x86_64-linux-gnu/libbz2.so.1.0
cp -L /lib/x86_64-linux-gnu/libcom_err.so.2         $topdir/lib/x86_64-linux-gnu/libcom_err.so.2
cp -L /lib/x86_64-linux-gnu/libcrypt.so.1           $topdir/lib/x86_64-linux-gnu/libcrypt.so.1
cp -L /lib/x86_64-linux-gnu/libc.so.6               $topdir/lib/x86_64-linux-gnu/libc.so.6
cp -L /lib/x86_64-linux-gnu/libdl.so.2              $topdir/lib/x86_64-linux-gnu/libdl.so.2
cp -L /lib/x86_64-linux-gnu/libkeyutils.so.1        $topdir/lib/x86_64-linux-gnu/libkeyutils.so.1
cp -L /lib/x86_64-linux-gnu/liblzma.so.5            $topdir/lib/x86_64-linux-gnu/liblzma.so.5
cp -L /lib/x86_64-linux-gnu/libm.so.6               $topdir/lib/x86_64-linux-gnu/libm.so.6
cp -L /lib/x86_64-linux-gnu/libnsl.so.1             $topdir/lib/x86_64-linux-gnu/libnsl.so.1
cp -L /lib/x86_64-linux-gnu/libnss_dns.so.2         $topdir/lib/x86_64-linux-gnu/libnss_dns.so.2
cp -L /lib/x86_64-linux-gnu/libpcre.so.3            $topdir/lib/x86_64-linux-gnu/libpcre.so.3
cp -L /lib/x86_64-linux-gnu/libpthread.so.0         $topdir/lib/x86_64-linux-gnu/libpthread.so.0
cp -L /lib/x86_64-linux-gnu/libresolv.so.2          $topdir/lib/x86_64-linux-gnu/libresolv.so.2
cp -L /lib/x86_64-linux-gnu/librt.so.1              $topdir/lib/x86_64-linux-gnu/librt.so.1
cp -L /lib/x86_64-linux-gnu/libz.so.1               $topdir/lib/x86_64-linux-gnu/libz.so.1
cp -L /usr/lib/libonig.so.2                         $topdir/usr/lib/libonig.so.2
cp -L /usr/lib/libqdbm.so.14                        $topdir/usr/lib/libqdbm.so.14
cp -L /usr/lib/x86_64-linux-gnu/libcrypto.so.1.0.0  $topdir/usr/lib/x86_64-linux-gnu/libcrypto.so.1.0.0
cp -L /usr/lib/x86_64-linux-gnu/libdb-5.1.so        $topdir/usr/lib/x86_64-linux-gnu/libdb-5.1.so
cp -L /usr/lib/x86_64-linux-gnu/libgssapi_krb5.so.2 $topdir/usr/lib/x86_64-linux-gnu/libgssapi_krb5.so.2
cp -L /usr/lib/x86_64-linux-gnu/libk5crypto.so.3    $topdir/usr/lib/x86_64-linux-gnu/libk5crypto.so.3
cp -L /usr/lib/x86_64-linux-gnu/libkrb5.so.3        $topdir/usr/lib/x86_64-linux-gnu/libkrb5.so.3
cp -L /usr/lib/x86_64-linux-gnu/libkrb5support.so.0 $topdir/usr/lib/x86_64-linux-gnu/libkrb5support.so.0
cp -L /usr/lib/x86_64-linux-gnu/libssl.so.1.0.0     $topdir/usr/lib/x86_64-linux-gnu/libssl.so.1.0.0
cp -L /usr/lib/x86_64-linux-gnu/libxml2.so.2        $topdir/usr/lib/x86_64-linux-gnu/libxml2.so.2

# copy & symlink mini_sendmail static binary
if [ -f "$MINI_SENDMAIL_PATH" ]; then
  cp -a $MINI_SENDMAIL_PATH $topdir/bin/
  cd $topdir/usr/sbin
  ln -sf ../../bin/mini_sendmail sendmail
else
  echo "  [!] mini_sendmail binary not found! "
  echo -n "  [!] Press ENTER if you're OK with that, else CTRL+C and check if the MINI_SENDMAIL_PATH variable is correct >> "
  echo
fi

echo "  [*] Adding user/group information"

# add user and group information
lastuid=`cat /etc/passwd | grep -ve "^nobody"  | cut -d ":" -f 3 | sort -n | tail -n1`
lastgid=`cat /etc/group  | grep -ve "^nogroup" | cut -d ":" -f 3 | sort -n | tail -n1`
groupadd --system --gid $(($lastgid+1)) $fullname
useradd --system --shell /bin/false --home $topdir --uid $((lastuid+1)) --gid $((lastgid+1)) $fullname
adduser $WWW_USER $fullname


# check if website content directory/file was provided, copy over to 'htdocs/' if so
if [ -n "$webdir" ]; then
  echo "  [*] Attempting website content deployment"

  # check if $webdir is a directory
  if [ -d "$webdir" ]; then
    cp -a $webdir/* $topdir/htdocs

  # else, check if it has a supported extension
  else
    ftype=`file $webdir | grep -o "bzip2\|gzip"`

    # ok, we have either a '.gz' or '.bz2' file
    if [ -n "$ftype" ]; then
      if [ "$ftype" == "bzip2" ]; then 
        tar -jxf $webdir -C $topdir/htdocs
      elif [ "$ftype" == "gzip" ]; then 
        tar -zxf $webdir -C $topdir/htdocs
     fi

    # wrong file supplied?
    else
      echo "  [!] Website content $webdir is not a directory, .tar.gz or .tar.bz2 file, skipping copy!"
    fi
  fi
fi

# set folder permissions
set_perms

# attempt webserver autoconfiguration if we've been provided with a template
if [ $tflag ]; then
  run_autoconf
fi

# are we doing socket mounts?
if [ $dflag ]; then
  echo "  [*] Updating $RC_MOUNT to enable database socket access"

  # check if this is the first time we're mounting any DB socket
  # update /etc/rc.local and create/set perms for $RC_MOUNT if so
  echo "  [*] Checking if this is the first socket mount we're doing"
  echo -n "  [*] Searching $RC_MOUNT: "
  cat /etc/rc.local | grep $RC_MOUNT

  if [ $? -ne 0 ]; then
    echo "not found."
    sed -i "s/^exit 0/$(skipslashes $RC_MOUNT)\nexit 0/" /etc/rc.local
    if [ ! -f "$RC_MOUNT" ]; then
      touch $RC_MOUNT
      chmod +x $RC_MOUNT
    fi
  fi

  # append mounting for this vhost to $RC_MOUNT
  if [ "$db" == "M" ]; then
    echo "mount --bind $MYSQL_DIR $topdir$MYSQL_DIR" >> $RC_MOUNT
    mount --bind $MYSQL_DIR $topdir$MYSQL_DIR
  elif [ "$db" == "P" ]; then
    echo "mount --bind $POSTGRES_DIR $topdir$POSTGRES_DIR" >> $RC_MOUNT
    mount --bind $POSTGRES_DIR $topdir$POSTGRES_DIR 
  fi
fi

echo
echo "  [*] All done, check $topdir for your new chrooted virtualhost!"
echo "  [*] You may now copy over files to $topdir/htdocs, if you haven't used the '-w' option. Don't forget to set writable folders."
echo "  [*] If you haven't done it yet, re-run the script using the '-l' option to restore database dumps. See ya next time!"
