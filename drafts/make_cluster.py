#!/usr/bin/env python

import sys, os, time, re

def main(argv):
   
    if  len(argv) <= 1:
        get_out( "file name of cluster tarball required")
    if  not os.path.exists(argv[1]):
        get_out( "cluster tarball file not found")
    check_for_tar()
    check_for_sandbox()
    cluster_basedir = expand_tarball(argv[1])
    install_sandbox(cluster_basedir)
    cluster_sandbox_dir = make_cluster_dirs()
    make_cluster_config(cluster_basedir, cluster_sandbox_dir)
    start_ndb(cluster_basedir, cluster_sandbox_dir ) 
    start_mysql_server(cluster_sandbox_dir)
    print "Please wait. Giving the cluster time to catch up"
    check_for_cluster(cluster_basedir)
    test_cluster(cluster_basedir, cluster_sandbox_dir)
    print "to shut down the cluster, type:"
    print cluster_basedir + "/bin/ndb_mgm -e shutdown"

def check_for_cluster(cluster_basedir):
    cmd = cluster_basedir + '/bin/ndb_mgm -e show'
    regexp = re.compile('.*id=50.*not connected')

    count = 0
    f_output = os.popen(cmd)
    output   = f_output.read()
    while re.search(regexp, output):
        print output
        print "It may take up to 180 seconds to initialize ... (", count, ")"
        f_output.close()
        f_output = os.popen(cmd)
        output=f_output.read()
        time.sleep(5)
        count += 5
    print output

def start_mysql_server(cluster_sandbox_dir):
     print_exec(cluster_sandbox_dir + '/clear')
     print_exec(cluster_sandbox_dir + '/start')

def test_cluster(cluster_basedir, cluster_sandbox_dir):
     print_exec(cluster_sandbox_dir + \
             '/use -vvv -e "create table test.t1(i int not null primary key)engine=ndb"')
     print_exec(cluster_sandbox_dir + \
             '/use -vvv -e "show create table test.t1\\G"')

def print_exec(cmd):
    print "\n++ " + cmd
    os.system(cmd)

def start_ndb(cluster_basedir, cluster_sandbox_dir):
     mgmt_init_cmd = cluster_basedir + "/bin/ndb_mgmd " + \
            "-f " + cluster_sandbox_dir + "/my_cluster/conf/config.ini " + \
             "--initial " +\
             "--configdir=" + cluster_sandbox_dir + "/my_cluster/conf/"
     ndbd_init_cmd = cluster_basedir + "/bin/ndbd -c localhost:1186"
     print_exec(mgmt_init_cmd)
     print_exec(ndbd_init_cmd)
     print_exec(ndbd_init_cmd)
     print_exec(cluster_basedir + '/bin/ndb_mgm -e show')

def make_cluster_config(cluster_basedir, cluster_sandbox_dir):
    #my_cnf = os.path.join(cluster_sandbox_dir, 
    #        'my_cluster/conf', 'my.cnf')
    config_ini = os.path.join(cluster_sandbox_dir, 
            'my_cluster/conf', 'config.ini')
    #f = open(my_cnf, 'w')
    #f.writelines([ '[mysqld]', 'ndbcluster', 
    #        'datadir=' + cluster_sandbox_dir +'/mysqld_data',
    #        'basedir=' + cluster_basedir,  
    #        'port=5000' ])
    # f.close()
    f = open(config_ini, 'w')
    for line in [ 
          '[ndb_mgmd]',
          'hostname=localhost',
          'datadir=' + cluster_sandbox_dir + '/my_cluster/ndb_data',
          'id=1',
          '',
          '[ndbd default]',
          'noofreplicas=2',
          'datadir=' + cluster_sandbox_dir +'/my_cluster/ndb_data',
          '[ndbd]',
          'hostname=localhost', 
          'id=3',
          '',
          '[ndbd]', 
          'hostname=localhost',
          'id=4',
          '',
          '[mysqld]', 
          'id=50'
          ]:
        f.write(line + "\n")
    f.close()

def make_cluster_dirs():
    cluster_sandbox_dir = '';
    if os.environ.has_key('SANDBOX_HOME'):
        cluster_sandbox_dir = os.path.join(os.environ['SANDBOX_HOME'], 'mcluster')
    else:
        cluster_sandbox_dir = os.path.join(os.environ['HOME'], 'sandboxes', 'mcluster')
    if os.path.isdir(cluster_sandbox_dir):
        for dir in [ 'my_cluster', 'my_cluster/ndb_data',
                'my_cluster/mysqld_data', 'my_cluster/conf']:
            os.mkdir( os.path.join(cluster_sandbox_dir, dir))
    else:
        get_out("Could not find MySQL sandbox installed directory " + cluster_sandbox_dir)
    return cluster_sandbox_dir

def install_sandbox(cluster_directory):
    cmd = "low_level_make_sandbox " + \
          "--basedir=" + os.path.abspath(cluster_directory) + " " + \
          "--sandbox_directory=mcluster " + \
          "--install_version=5.1 " + \
          "--sandbox_port=5144 "  + \
          "--no_ver_after_name " + \
          "--no_run " + \
          "--force " + \
          "--my_clause=log-error=msandbox.err " + \
          "--my_clause=ndbcluster " 
    print_exec(cmd)

def expand_tarball(fname):    
    dirname = os.path.basename(fname)[:-7]
    if os.path.isdir(dirname):
        return dirname
    else:
        print "Extracting tar file. Please wait"
        print_exec( "tar -xzf " + fname )
        if os.path.isdir(dirname):
            return dirname
        else:
            get_out("error expanding tarball")

def check_for_sandbox():
    if not find_in_path('low_level_make_sandbox'):
        get_out( "could not find 'MySQL::Sandbox' in PATH\n" +
                 "Please install it from http://mysqlsandbox.net"
               )

def check_for_tar():
    if not find_in_path('tar'):
        get_out ("could not find 'tar' in PATH")

def find_in_path(fn):
    for p in os.environ['PATH'].split(':'):
        # print p, fn, os.path.join(p, fn)
        if os.path.exists(os.path.join(p, fn)):
            return True
    return False

def get_out(msg):
    print msg
    exit(1)


if __name__ == '__main__':
    main(sys.argv)

