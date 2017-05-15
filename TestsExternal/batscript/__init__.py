import os

if not os.environ['__INIT__']:
	raise ValueError("Environment must be initialized through a call to __init__.bat before call to __init__.py")

TESTS_ROOT = os.path.abspath(os.path.realpath(os.environ['TESTS_ROOT']))

# tests output directory
TEST_OUTPUT_BASE_DIR = os.path.abspath(TESTS_ROOT + '/_output')

# static test data directory
TEST_STATIC_DATA_BASE_DIR = os.path.abspath(TESTS_ROOT + '/_testdata_static')

# dynamic test data directory
TEST_DYNAMIC_DATA_BASE_DIR = os.path.abspath(TESTS_ROOT + '/_testdata_dynamic')

# temporary files directory
TEST_TEMP_BASE_DIR = os.path.abspath(TESTS_ROOT + '/../../Temp')

# map of generated data cache
TEST_DYNAMIC_DATA_GEN_CACHE_MAP = {
		'svn_empty_db' : TEST_DYNAMIC_DATA_BASE_DIR + '/svn_empty_db',
	}

# external tools root directory
EXTERNAL_TOOLS_ROOT = os.path.abspath(os.environ['EXTERNAL_TOOLS_ROOT'])

TEST_SVN_TOOLSET_ROOT = os.path.abspath(EXTERNAL_TOOLS_ROOT + '/scm/svn')

# most popular at first, bases on this answers: http://stackoverflow.com/questions/2341134/command-line-svn-for-windows
TEST_SVN_TOOLSET_MAP = [
		{ 'name' : 'tortoisesvn-win32', 'variants' : ['1.9.5.27581-1.9.5', '1.8.12.26645-1.8.14', '1.7.15.25753-1.7.18'] },
		{ 'name' : 'collabnet-win32',   'variants' : ['1.9.5-1', '1.8.17-1', '1.7.19-1'] },
		{ 'name' : 'sliksvn-win32',     'variants' : ['1.9.5', '1.8.17', '1.7.22'] },
		{ 'name' : 'cygwin-win32',      'variants' : ['1.9.5-1', '1.8.17-1', '1.7.14-1'] },
		{ 'name' : 'visualsvn-win32',   'variants' : ['1.9.5'] },
		{ 'name' : 'win32svn',          'variants' : ['1.8.17', '1.7.22' ] }
	]
