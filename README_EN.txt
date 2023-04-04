* README_EN.txt
* 2023.04.04
* svncmd

CAUTION:
  DEVELOPMENT OF THIS PROJECT IS ABANDONED.

1. DESCRIPTION
2. LICENSE
3. REPOSITORIES
4. INSTALLATION
5. THIRD PARTY SETUP
5.1. ssh+svn/plink setup
6. KNOWN ISSUES
6.1. External application issues
6.1.1. svn+ssh issues
6.1.1.1. Message `svn: E170013: Unable to connect to a repository at URL 'svn+ssh://...'`
         `svn: E170012: Can't create tunnel`
6.1.1.2. Message `Can't create session: Unable to connect to a repository at URL 'svn+ssh://...': `
         `To better debug SSH connection problems, remove the -q option from ssh' in the [tunnels] section of your Subversion configuration file. `
         `at .../Git/mingw64/share/perl5/Git/SVN.pm line 310.'`
6.1.1.3. Message `Keyboard-interactive authentication prompts from server:`
         `svn: E170013: Unable to connect to a repository at URL 'svn+ssh://...'`
         `svn: E210002: To better debug SSH connection problems, remove the -q option from 'ssh' in the [tunnels] section of your Subversion configuration file.`
         `svn: E210002: Network connection closed unexpectedly`
7. AUTHOR

-------------------------------------------------------------------------------
1. DESCRIPTION
-------------------------------------------------------------------------------
Set of batch scripts (experimental) for the svn command line tools including
the svn command line tools (Win32) as is from:
* TortoiseSVN
* CollabNet
* SlikSVN
* Cygwin
* VisualSVN
* win32svn

-------------------------------------------------------------------------------
2. LICENSE
-------------------------------------------------------------------------------
The MIT license (see included text file "license.txt" or
https://en.wikipedia.org/wiki/MIT_License)

-------------------------------------------------------------------------------
3. REPOSITORIES
-------------------------------------------------------------------------------
Primary:
  * https://github.com/andry81/svncmd/branches
    https://github.com/andry81/svncmd.git
First mirror:
  * https://sf.net/p/svncmd/svncmd/ci/master/tree
    https://git.code.sf.net/p/svncmd/svncmd
Second mirror:
  * https://bitbucket.org/andry81/svncmd/branches
    https://bitbucket.org/andry81/svncmd.git

-------------------------------------------------------------------------------
4. INSTALLATION
-------------------------------------------------------------------------------
run configure.bat

-------------------------------------------------------------------------------
5. THIRD PARTY SETUP
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
5.1. ssh+svn/plink setup
-------------------------------------------------------------------------------
Based on: https://stackoverflow.com/questions/11345868/how-to-use-git-svn-with-svnssh-url/58641860#58641860

The svn+ssh protocol must be setuped using both the private and the public ssh
key.

In case of in the Windows usage you have to setup the ssh key before run the
svn client using these general steps related to the native Windows `svn.exe`
(should not be a ported one, for example, like the `msys` or `cygwin` tools
which is not fully native):

1. Install the `putty` client.
2. Generate the key using the `puttygen.exe` utility and the correct type of
   the key dependent on the svn hub server (Ed25519, RSA, DSA, etc).
3. Install the been generated public variant of the key into the svn hub server
   by reading the steps from the docs to the server.
4. Ensure that the `SVN_SSH` environment variable in the generated
   `config.env.yaml` file is pointing a correct path to the `plink.exe` and
   uses valid arguments. This would avoid hangs in scripts because of
   interactive login/password request and would avoid usage svn repository
   urls with the user name inside.
5. Ensure that all svn working copies and the `externals` properties in them
   contains valid svn repository urls with the `svn+ssh://` prefix. If not then
   use the `*~svn~relocate.*` scrtip(s) to switch onto it. Then fix all the
   rest urls in the `externals` properties, for example, just by remove the url
   scheme prefix and leave the `//` prefix instead.
6. Run the `pageant.exe` in the background with the previously generated
   private key (add it).
7. Test the connection to the svn hub server through the `putty.exe` client.
   The client should not ask for the password if the `pageant.exe` is up and
   running with has been correctly setuped private key. The client should not
   ask for the user name either if the `SVN_SSH` environment variable is
   declared with the user name.

The `git` client basically is a part of ported `msys` or `cygwin` tools, which
means they behaves a kind of differently.

The one of the issues with the message `Can't create session: Unable to connect
to a repository at URL 'svn+ssh://...': Error in child process: exec of ''
failed: No such file or directory at .../Git/mingw64/share/perl5/Git/SVN.pm
line 310.` is the issue with the `SVN_SSH` environment variable. The variable
should be defined with an utility from the same tools just like the `git`
itself. The attempt to use it with the standalone `plink.exe` from the `putty`
application would end with that message.

So, additionally to the steps for the `svn.exe` application you should apply,
for example, these steps:

1. Drop the usage of the `SVN_SSH` environment variable and remove it.
2. Run the `ssh-pageant` from the `msys` or `cygwin` tools (the `putty`'s
   `pageant` must be already run with the valid private key). You can read
   about it, for example, from here: https://github.com/cuviper/ssh-pageant
   ("ssh-pageant is a tiny tool for Windows that allows you to use SSH keys
   from PuTTY's Pageant in Cygwin and MSYS shell environments.")
3. Create the environment variable returned by the `ssh-pageant` from the
   stdout, for example: `SSH_AUTH_SOCK=/tmp/ssh-hNnaPz/agent.2024`.
4. Use urls in the `git svn ...` commands together with the user name as stated
   in the documentation
   (https://git-scm.com/docs/git-svn#Documentation/git-svn.txt---usernameltusergt ):
   `svn+ssh://<USERNAME>@svn.<url>.com/repo`
   ("For transports that SVN handles authentication for (http, https, and plain
   svn), specify the username. For other transports (e.g. svn+ssh://), you
   **must include the username in the URL**,
   e.g. svn+ssh://foo@svn.bar.com/project")

These instructions should help to use `git svn` commands together with the
`svn` commands.

-------------------------------------------------------------------------------
6. KNOWN ISSUES
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
6.1. External application issues
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
6.1.1. svn+ssh issues
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
6.1.1.1. Message `svn: E170013: Unable to connect to a repository at URL 'svn+ssh://...'`
         `svn: E170012: Can't create tunnel`
-------------------------------------------------------------------------------

Issue #1:

  The `svn ...` command was run w/o properly configured putty plink utility or
  w/o the `SVN_SSH` environment variable with the user name parameter.

Solution:

  Carefully read the `ssh+svn/plink setup` section to fix most of the cases.

Issue #2

  The `SVN_SSH` environment variable have has the backslash characters - `\`.

Solution:

  Replace all the backslash characters by forward slash character - `/` or by
  double baskslash character - `\\`.

-------------------------------------------------------------------------------
6.1.1.2. Message `Can't create session: Unable to connect to a repository at URL 'svn+ssh://...': `
         `To better debug SSH connection problems, remove the -q option from ssh' in the [tunnels] section of your Subversion configuration file. `
         `at .../Git/mingw64/share/perl5/Git/SVN.pm line 310.'`
-------------------------------------------------------------------------------

Issue:

  The `git svn ...` command should not be called with the `SVN_SSH` variable
  declared for the `svn ...` command.

Solution:

  Read docs about the `ssh-pageant` usage from the msys tools to fix that.

  See details: https://stackoverflow.com/questions/31443842/svn-hangs-on-checkout-in-windows/58613014#58613014

-------------------------------------------------------------------------------
6.1.1.3. Message `Keyboard-interactive authentication prompts from server:`
         `svn: E170013: Unable to connect to a repository at URL 'svn+ssh://...'`
         `svn: E210002: To better debug SSH connection problems, remove the -q option from 'ssh' in the [tunnels] section of your Subversion configuration file.`
         `svn: E210002: Network connection closed unexpectedly`
-------------------------------------------------------------------------------

Related command: `git svn ...`

Issue #1:

  Network is disabled:

Issue #2:

  The `pageant` application is not running or the private SSH key is not added.

Issue #3:

  The `ssh-pageant` utility is not running or the `git svn ...` command does
  run without the `SSH_AUTH_SOCK` environment variable properly registered.

Solution:

  Read the details in the `ssh+svn/plink setup` section.

-------------------------------------------------------------------------------
7. AUTHOR
-------------------------------------------------------------------------------
Andrey Dibrov (andry at inbox dot ru)
