function save_data!(A::Array{T,1}, dset::HDF5Dataset, src_ind::AbstractRange{Int}, dest_ind::AbstractRange{Int}) where T
  dsel_id = HDF5.hyperslab(dset, src_ind)
  V = view(A, dest_ind)
  memtype = HDF5.datatype(A)
  memspace = HDF5.dataspace(V)
  HDF5.h5d_write(dset.id, memtype.id, memspace.id, dsel_id, dset.xfer, V)
  HDF5.close(memtype)
  HDF5.close(memspace)
  HDF5.h5s_close(dsel_id)
  return nothing
end
