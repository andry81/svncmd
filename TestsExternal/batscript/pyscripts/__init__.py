import os

TEST_DATA_SVN_EMPTY_DB_DIR = os.environ['TEST_DATA_COMMON_GEN_DIR'] + '\svn_empty_db'
TEST_DATA_SVN_REPOS_BASE_DIR = os.environ['TEST_SRC_BASE_DIR'] + '\_svnrepos'

TEST_SVN_TOOLSET_LIST_ROOT_PATH = os.environ['EXTERNAL_TOOLS_PATH'] + '\scm\svn'
# most popular at first, bases on this answers: http://stackoverflow.com/questions/2341134/command-line-svn-for-windows
TEST_SVN_TOOLSET_TABLE_LIST = [
    { 'name' : 'tortoisesvn-win32', 'variants' : ['1.9.5.27581-1.9.5', '1.8.12.26645-1.8.14', '1.7.15.25753-1.7.18'] },
    { 'name' : 'collabnet-win32',   'variants' : ['1.9.5-1', '1.8.17-1', '1.7.19-1'] },
    { 'name' : 'sliksvn-win32',     'variants' : ['1.9.5', '1.8.17', '1.7.22'] },
    { 'name' : 'cygwin-win32',      'variants' : ['1.9.5-1', '1.8.17-1', '1.7.14-1'] },
    { 'name' : 'win32svn',          'variants' : ['1.8.17', '1.7.22' ] }
  ]
