package Tips;

use strict;
use warnings;

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw( print_tip );

use Term::ANSIColor qw( :constants );
$Term::ANSIColor::AUTORESET = 1;

# at the request of dev, use 'FB' instead of 'case' so as to not skew actual
# FogBugz cases (sometimes people will paste this irrelevant SSP output into cases)
sub print_tip {
    my @tips = (
        '[FB 75793] (By design) Proxy subdomains are not created for addon domains',
        '[FB 72801] (By design) File Manager creates new files with 0600 perms, even when saving an existing file as a new one',
        '[FB 72733] (By design) File Manager\'s "Compress" feature has a hard coded timeout due to using cPanel\'s form upload logic',        '[FB 65253] cPHulk may report root logins to Pure-FTPd despite no evidence being found',
        '[FB 63530] When setting up a remote MySQL server, that server must have the openssh-clients package installed',
        '[FB 63283] (By design) In cPanel <= 11.38, bandwidth will process during blackout hours if it was started before the blackout hour',
        '[FB 63193] File Manager showing "Out of memory" in cPanel error_log? Try renaming $HOME/$USER/.cpanel/datastore/SYSTEMMIME',
        '[FB 62819] "License File Expired: LTD: 1334782495 NOW: 1246416504 FUT!" likely just means the server clock is wrong',
        '[FB 62054] (By design) The "Dedicated IP" box can only be modified when creating a package - not when editing',
        '[FB 61735] (By design) "/u/l/c/whostmgr/bin/whostmgr2 --updatetweaksettings" destroys custom proxy subdomain records. Use WHM >> Tweak Settings instead.',
        '[FB 61516] cPanel\'s Java SSH term app may say shell access is disabled, even when it is enabled',
        '[FB 60471] PureFTPd allows FTP users to follow symlinks',
        '[FB 58625] Apache 2.0.x links to the wrong PCRE libs. This can cause preg_match*() errors, and "PCRE is not compiled with UTF-8 support"',
        '[FB 50745] (By design) The cPanel UI displays differently (more columns than rows) when changing your locale',
         '[FB 46853] Customer complaining that they can\'t log into cPanel as root? Update FB 46853',
        '[FB 44884] upcp resets Mailman lists\' hostnames. pre/postupcp hooks workaround in ticket 3541643',
        '[FB 43944] layer1/layer2.cpanel.net is deprecated. The correct location is httpupdate.cpanel.net',
        '[FB 42027] "Recently Uploaded Cgi Script Mail" scans and sends email alerts about downloaded files too',
        'mod_userdir URLs (/~username) are not compatible with FCGI when Apache\'s suexec is enabled (cP Docs: tinyurl.com/bbd8fn2)',
        'For a list of obscure issues, see the RareIssues wiki article',
        '11.35+: Use /scripts/check_cpanel_rpms to fix problems in /usr/local/cpanel/3rdparty/  - not checkperlmodules',
        'php.ini for phpMyAdmin, phpPgAdmin, Horde, and RoundCube can be found in /usr/local/cpanel/3rdparty/etc/',
        'If Dovecot/POP/IMAP dies every day around the same time, the server\'s clock could be skewed. Check /var/log/maillog for "moved backwards"',
        '"Allowed memory size of x bytes exhausted" when uploading a db via phpMyAdmin may be resolved by increasing max_allowed_packet',
        'Need to edit php.ini for Horde, RoundCube, phpMyAdmin, or phpPgAdmin? Edit /u/l/c/3rdparty/etc/php.ini, then run /u/l/c/b/install_php_inis',
        'Seeing "domainadmin" errors (e.g. "domainadmin-domainexistsglobal")? Check the Domainadmin-Errors wiki article',
        'Transfers showing "sshcmdpermissiondeny"? Check for modified openssh-clients package (see ticket 3664533)',
        'Learn how cPanel 11.36+ handles rpms: http://go.cpanel.net/rpmversions',
        'Learn what\'s new in 11.36: http://docs.cpanel.net/twiki/bin/vief/AllDocumentation/1136ReleaseNotes',
        'Use "rlog <file>" to see a file\'s revision history, and "co -p1.1 <file>" (for example) to see that revision',
        'Files under revision control: fstab, localdomains, named.conf, passwd, shadow, trueuserowners, httpd.conf, php.ini (system and cPanel)',
        'Imagick install issues on PHP 5.4? You may need to run \'pear config-set preferred_state beta\' (see ticket 3754991)',
        'Need to enable ZTS support for PHP? Try \'--enable-maintainer-zts\' (see ticket 3769493)',
        'WHM\'s "Apache mod_userdir Tweak" can be toggled via /scripts/userdirctl',
        'Issues with MySQL for a single user? Check for /home/${USER}/.my.cnf',
        'Services reported as failing while backups are running? chksrvd may be simply timing out due to excessive disk I/O',
        'Blank page in File Manager\'s HTML Editor and iconv "illegal input sequence" in cPanel error_log? Try windows-1251 encoding (see ticket 4088633)',
        'CentOS 5.x and CloudLinux 5.x do not support SNI. See the "SNI" wiki article for more info',
        'domlogs are created 0644 by default. cpanellogd changes permissions on them to 0640 a few minutes later',
        'cPanel >> Error Log only searches "recent" logs in Apache\'s error_log . Showing as blank? Maybe there are no recent errors',
        'Horde showing "server configuration did not allow file to be uploaded"? Check disk/inode usage on /tmp',
        'IMAP/webmail showing no email? The cPanel account may have been over its quota. Try renaming dovecot-uidlist, send account an email (see ticket 4314723)',
    );

    my $num  = int rand scalar @tips;
    print BOLD WHITE ON_BLACK "\tDid you know? $tips[$num]" . RESET . "\n\n";
}

1;
