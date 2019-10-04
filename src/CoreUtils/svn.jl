function get_svn(url::String, dest::String)

  if isdir(dest)
    println(dest * " exists; not downloading.")
  else
    println("dowloading via SVN...")
    status = 1
    if Sys.iswindows()
      status = (try
        p = run(`cmd /c svn export $url $dest`)
        0
      catch err
        @warn(string("error thrown: ", err))
        1
      end)
    else
      status = (try
        p = run(`svn export $url $dest`)
        p.exitcode
      catch err
        @warn(string("error thrown: ", err))
        1
      end)
    end
    if status != 0
      err_string = "download failed. Is a command-line SVN client installed?

      (type \"run(`svn --version`)\"; if an error occurs, SVN isn't installed.)

      Subversion for Ubuntu: sudo apt install subversion
      Subversion for OS X: pkg_add subversion
      SlikSVN Windows client: https://sliksvn.com/download/
      "
      error(err_string)
    end
  end
  return nothing
end
