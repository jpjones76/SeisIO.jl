# -*- coding: utf-8 -*-
#
# SeisIO documentation build configuration file, created by
# sphinx-quickstart on Sun May 22 18:44:14 2016.
#
# This file is execfile()d with the current directory set to its
# containing dir.
#
# Note that not all possible configuration values are present in this
# autogenerated file.
#
# All configuration values have a default; values that are commented out
# serve to show the default.

import sys
import os
import sphinx_rtd_theme

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
#sys.path.insert(0, os.path.abspath('.'))

# -- General configuration ------------------------------------------------

# If your documentation needs a minimal Sphinx version, state it here.
#needs_sphinx = '1.0'

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = [
    'sphinx_rtd_theme',
]
html_css_files = [
    'css/custom.css',
]

# Add any paths that contain templates here, relative to this directory.
templates_path = ['_templates']

# The suffix(es) of source filenames.
# You can specify multiple suffix as a list of string:
# source_suffix = ['.rst', '.md']
source_suffix = '.rst'

# The encoding of source files.
source_encoding = 'utf-8-sig'
# source_encoding = 'utf_16'

# The master toctree document.
master_doc = 'index'

# General information about the project.
project = u'SeisIO'
copyright = u'2016-2020, Joshua P. Jones, Ph.D.'
author = u'Joshua P. Jones, Ph.D.'

# The version info for the project you're documenting, acts as replacement for
# |version| and |release|, also used in various other places throughout the
# built documents.
#
# The short X.Y version.
version = u'1.2'
# The full version, including alpha/beta/rc tags.
release = u'1.2.1'

# The language for content autogenerated by Sphinx. Refer to documentation
# for a list of supported languages.
#
# This is also used if you do content translation via gettext catalogs.
# Usually you set "language" from the command line for these cases.
language = None

# There are two options for replacing |today|: either, you set today to some
# non-false value, then it is used:
#today = ''
# Else, today_fmt is used as the format for a strftime call.
#today_fmt = '%B %d, %Y'

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This patterns also effect to html_static_path and html_extra_path
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']

# The reST default role (used for this markup: `text`) to use for all
# documents.
#default_role = None

# If true, '()' will be appended to :func: etc. cross-reference text.
#add_function_parentheses = True

# If true, the current module name will be prepended to all description
# unit titles (such as .. function::).
#add_module_names = True

# If true, sectionauthor and moduleauthor directives will be shown in the
# output. They are ignored by default.
#show_authors = False

# The name of the Pygments (syntax highlighting) style to use.
pygments_style = 'sphinx'

# A list of ignored prefixes for module index sorting.
#modindex_common_prefix = []

# If true, keep warnings as "system message" paragraphs in the built documents.
#keep_warnings = False

# If true, `todo` and `todoList` produce output, else they produce nothing.
todo_include_todos = False


# -- Options for HTML output ----------------------------------------------

html_theme = 'sphinx_rtd_theme'
html_theme_options = {
    'canonical_url': '',
    'collapse_navigation': False,
    'sticky_navigation': False,
    'navigation_depth': 1,
    'includehidden': True,
    'titles_only': True,
    'sidebarwidth': '18em'
}

html_title = u'SeisIO v1.2.1'
html_short_title = u'SeisIO v1.2.1'
#html_logo = None
#html_favicon = None
html_static_path = ['_static']
#html_use_smartypants = True
#html_sidebars = {}
#html_additional_pages = {}
#html_domain_indices = True
#html_use_index = True
#html_split_index = False
#html_show_sourcelink = True
#html_show_sphinx = True
#html_show_copyright = True
#html_use_opensearch = ''
#html_file_suffix = None
#html_search_language = 'en'
#html_search_options = {'type': 'default'}
#html_search_scorer = 'scorer.js'
htmlhelp_basename = 'SeisIOdoc'

# -- Options for LaTeX output ---------------------------------------------
latex_engine = 'xelatex'
latex_elements = {
    'papersize': 'letterpaper',
    'pointsize': '11.5pt',
    'inputenc': '',
    'utf8extra': '',
    'preamble': '''

\usepackage{fontspec}
\setsansfont{Alata}
\setromanfont{Bookman Old Style}
\setmonofont{Cousine}

\usepackage{amsmath}
\usepackage{amssymb}
\usepackage{amsthm}
\usepackage{amscd}
\usepackage{amsfonts}
\usepackage[yyyymmdd]{datetime}
\usepackage{graphicx}%
\usepackage{fancyhdr}
\usepackage{cancel}
\usepackage{epsfig}
\usepackage{epstopdf}
\usepackage{float}
\usepackage[T1]{fontenc}
\usepackage{lineno}
\usepackage{longtable}
\usepackage{lscape}
\usepackage{multicol}
\usepackage{natbib}
\usepackage{psfrag}
\usepackage{relsize}
\usepackage{rotating}
\usepackage[active]{srcltx}
\usepackage{setspace}
\usepackage{supertabular}
\usepackage{subcaption}
\usepackage{textcomp}
\usepackage{framed}
\\setlength{\\leftmargini}{1.5em}
\\setlength{\\topmargin}{-10mm}
\\setlength{\\textwidth}{7in}
\\setlength{\oddsidemargin}{-8mm}
\\setlength{\\footskip}{1in}

''',
}
# \usepackage[top=0.5in, bottom=1in, left=1in, right=0.5in]{geometry}
# \setlength{\leftmargini}{1.5em}
# \setlength{\topmargin}{-10mm}
# \setlength{\textwidth}{7in}
# \setlength{\oddsidemargin}{-8mm}
# \setlength{\footskip}{1in}

# Grouping the document tree into LaTeX files. List of tuples
# (source start file, target name, title,
#  author, documentclass [howto, manual, or own class]).
latex_documents = [
    (master_doc, 'SeisIO.tex', u'SeisIO Documentation',
     u'Joshua P. Jones', 'manual'),
]

# The name of an image file (relative to this directory) to place at the top of
# the title page.
#latex_logo = None

# For "manual" documents, if this is true, then toplevel headings are parts,
# not chapters.
#latex_use_parts = False
# latex_toplevel_sectioning='part'

# If true, show page references after internal links.
#latex_show_pagerefs = False

# If true, show URL addresses after external links.
#latex_show_urls = False

# Documents to append as an appendix to all manuals.
#latex_appendices = []

# If false, no module index is generated.
#latex_domain_indices = True


# -- Options for manual page output ---------------------------------------

# One entry per manual page. List of tuples
# (source start file, name, description, authors, manual section).
man_pages = [
    (master_doc, 'seisio', u'SeisIO Documentation',
     [author], 1)
]

# If true, show URL addresses after external links.
#man_show_urls = False


# -- Options for Texinfo output -------------------------------------------

# Grouping the document tree into Texinfo files. List of tuples
# (source start file, target name, title, author,
#  dir menu entry, description, category)
texinfo_documents = [
    (master_doc, 'SeisIO', u'SeisIO Documentation',
     author, 'SeisIO', 'One line description of project.',
     'Miscellaneous'),
]

# Documents to append as an appendix to all manuals.
#texinfo_appendices = []

# If false, no module index is generated.
#texinfo_domain_indices = True

# How to display URL addresses: 'footnote', 'no', or 'inline'.
#texinfo_show_urls = 'footnote'

# If true, do not generate a @detailmenu in the "Top" node's menu.
#texinfo_no_detailmenu = False
