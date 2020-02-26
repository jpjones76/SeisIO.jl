# ===========================================================================
# Redirect info, warnings, and errors to the logger
out = open("runtests.log", "a")
logger = SimpleLogger(out)
global_logger(logger)
@info("stdout redirect and logging")

# Set some keyword defaults
SeisIO.KW.comp = 0x00
has_restricted = safe_isdir(path * "/SampleFiles/Restricted/")
keep_log = false
keep_samples = true
