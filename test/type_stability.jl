# The basics
@code_warntype SeisData()
@code_warntype SeisData(5)
@code_warntype S[3]
@code_warntype "XX.TMP01.00.BHZ" in S.id
@code_warntype findid("CC.LON..BHZ",S)

A = SeisData(3);
@code_warntype setindex!(A, C, 3)

# equality, emptiness, sizeof
@assert(S==S)
@code_warntype S==S
@code_warntype S==T
@code_warntype isequal(S,T)
@code_warntype isequal(S,T)
@code_warntype isempty(S)
@code_warntype sizeof(S)

# append, deleteat
s = r"EH";
V = SeisData(5);
@code_warntype append!(V,S)
@code_warntype deleteat!(V,3)
@code_warntype deleteat!(V,[3,4])
@code_warntype deleteat!(V,3:4)
@code_warntype append!(S, T)
@code_warntype S - s

# merge, pull
(S,T) = mktestseis();
t1 = B.t[1]; t2 = A.t[1]; x1 = B.x[1]; x2 = A.x[1]; fs = B.fs[1];
t_tmp = t_expand(t1, fs);
@code_warntype t_collapse(t_tmp, fs)
@code_warntype xtmerge(t1,x1,t2,x2,fs);
x = randn(1024); t = rand(Int, 1024); half_samp = 50000;
@code_warntype xtjoin!(x,t,half_samp)
@code_warntype t_expand(t1, fs)
@code_warntype merge!(S,T)
@code_warntype S[1] + T[2]
@code_warntype S[4] + T[3]
@code_warntype SeisData(S,T)
@code_warntype pull(S,4)

# println("note!...")
str1 = "ADGJALMGFLSFMGSLMFLChannel 5 sucks"
str2 = "HIGH SNR ON THIS CHANNEL"
note!(S,str2)
note!(S,str1)
