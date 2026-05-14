# SELinux examples
- Here is small example of vulnerable http server apache, it has allowed launching scripts with enabled function mod_cgi
- search script adds RCE vulnerability to apache, in workshop recording are steps how can SELinux prevent attacker from exploiting it
- included configuration of httpd is placed in: **/etc/httpd/httpd.conf**
- script is placed in: **/var/www/cgi-bin/search.sh**

--- 
## Usage
- there can be placed bash command as parameter: cmd="command"
- URL with the exploit: http://localhost/cgi-bin/search.sh?cmd=ls+-al+/home

---
- rest of th examples were shown directly on the servers we use, so these are not placed here
- below is included SELinux cheatsheet, which I created during implementation
---

# SELinux cheatsheet
## general selinux control

**get selinux status:** sestatus

**set selinux mode:** setenforce 0/1, 0 - permissive, 1 - enforcing

**set default selinux mode:** vim /etc/selinux/config

- SELINUX=permissive – SELinux logs but does not enforce
    
- SELINUX=disabled – SELinux is completely turned off (requires reboot)
    
- SELINUX=enforcing – Full enforcement mode
    

### these parameters will also be controlled in puppet:

class { 'selinux':  
mode => 'permissive',  
type => 'targeted',  
}

---

## view selinux contexts

-Z switch display selinux contexts

**get file context:** ls -alZ

**get process context:** ps auxZ

---

## AVC log messages

**get raw denials generated from midnight:** cat /var/log/audit/audit.log | grep avc

**get number of messages:** cat /var/log/audit/audit.log | grep avc | wc -l

**remove AVC messages from audit log:** sed -i '/type=AVC/d' /var/log/audit/audit.log

## usage of sealert

sealert -a <file_contaning_avc_logs> ( /var/log/audit/audit.log)

---

## **manually installing selinux module**

generate module from source messages: cat <source_avc_logs_file> | audit2allow -M <name_of_module>will generate source file and module itself

- source .te file
    
- module .pp file
    

**if editing of type enforcement .te file is needed, check of syntax:** checkmodule -M -m <enforcement_file>.te

**installing module from .te type enforcement file:** checkmodule -M -m -o <module_name>.mod <enforcement_file>.te, semodule_package -o <module_name>.pp -m <module_name>.mod

**install selinux module:** semodule -i <module_name>.pp

### puppet sample entry for context module installation:

selinux::module { 'wazuh_agent_nrpe_pph':  
ensure => 'present',  
source_te => 'puppet:///modules/monitoring/selinux/wazuh_agent.te',  
builder => 'simple'  
}

---

## **managing selinux modules**

- **list peoplepath custom installed modules:** semodule -l | grep pph
    
- **list our nrpe custom installed modules:** semodule -l | grep pph | grep nrpe
    

**remove, uninstall selinux module:** semodule -r <module_name>

**disable, but not remove selinux module:** semodule -d <module_name>

**if disabled, back enable:** semodule -e <disabled_module_name>

---

## file contexts

**list all installed contexts:** semanage fcontext -l

**list contexts for specific domain:** semanage fcontext -l | grep httpd

**add new context to specified path or file:** sudo semanage fcontext -a -t httpd_sys_content_t '/srv/www(/.*)?'

**remove context from specified path or file:** sudo semanage fcontext -d -t httpd_sys_content_t '/srv/www(/.*)?'

### puppet sample entry for set file context:

selinux::fcontext{'nagios_data_storage_pph':  
ensure => 'present',  
seltype => 'nagios_data_t',  
pathspec => '/usr/local/nagiosgraph/var/rrd(/.*)?',  
}

## file contexts labeling

**after new file contexts are installed, apply them to file with:** sudo restorecon -Rv <path>

**if label is different that should be, this will show the correct one:** matchpathcon <path>

**enable autorelabeling:** .autorelabel is present in root on the server

---

## port contexts

**get list of port contexts:** semanage port -l

**adjust context of specified port:** semanage port -a -t redis_port_t -p tcp 26380

**remove specified port from context:** semanage port -d -t redis_port_t -p tcp 26380

### puppet sample entry for set port context:

selinux::port { 'wazuh-agent-port':  
ensure => 'present',  
seltype => 'wazuh_agent_port_t',  
protocol => 'tcp',  
port => 55000,  
}

---

## selinux booleans

**list available selinux booleans:** semanage boolean -l

**get value for specific boolean:** getsebool <boolean_name>

**set boolean value:** setsebool <boolean_name> on/off

### puppet sample entry for set boolean:

selinux::boolean { 'httpd_can_sendmail':  
ensure => 'on',  
}

---

## Inspecting already installed policies - usage of seinfo

seinfo is part of yum package setools-console

view attributes assigned to specified context type: seinfo -x -t auditd_log_t

view all context types and their attributes: seinfo -x -t | grep “ “

> SELinux policy information tool.
> 
> positional arguments:  
> policy Path to the SELinux policy to query.
> 
> optional arguments:  
> -h, --help show this help message and exit  
> --version show program's version number and exit  
> -x, --expand Print additional information about the specified  
> components.  
> --flat Print without item count nor indentation.  
> -v, --verbose Print extra informational messages  
> --debug Enable debugging.
> 
> Component Queries:  
> -a [ATTR], --attribute [ATTR]  
> Print type attributes.  
> -b [BOOL], --bool [BOOL]  
> Print Booleans.  
> -c [CLASS], --class [CLASS]  
> Print object classes.  
> -r [ROLE], --role [ROLE]  
> Print roles.  
> -t [TYPE], --type [TYPE]  
> Print types.  
> -u [USER], --user [USER]  
> Print users.  
> --category [CAT] Print MLS categories.  
> --common [COMMON] Print common permission set.  
> --constrain [CLASS] Print constraints.  
> --default [CLASS] Print default_* rules.  
> --fs_use [FS_TYPE] Print fs_use statements.  
> --genfscon [FS_TYPE] Print genfscon statements.  
> --ibpkeycon [PKEY[-PKEY]]  
> Infiniband pkey statements.  
> --ibendportcon [NAME]  
> Infiniband endport statements.  
> --initialsid [NAME] Print initial SIDs (contexts).  
> --netifcon [DEVICE] Print netifcon statements.  
> --nodecon [ADDR] Print nodecon statements.  
> --permissive [TYPE] Print permissive types.  
> --polcap [NAME] Print policy capabilities.  
> --portcon [PORTNUM[-PORTNUM]]  
> Print portcon statements.  
> --sensitivity [SENS] Print MLS sensitivities.  
> --typebounds [BOUND_TYPE]  
> Print typebounds statements.  
> --validatetrans [CLASS]  
> Print validatetrans.  
> --all Print all of the above. On a Xen policy, the Xen  
> components will also be printe
