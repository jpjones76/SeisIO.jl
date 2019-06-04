# Addition
#
# commutativity
# S1 + S2 == S2 + S1
# S + C == C + S
# C1 + C2 == C2 + C1
# S + U - U == S (for sorted S)
#
# associativity
# (S1 + S2) + S3 == S1 + (S2 + S3)
# (S1 + S2) + C == S1 + (S2 + C)
function +(S::T, U::T) where {T<:GphysData}
  Ω = deepcopy(S)
  append!(Ω, U)
  merge!(Ω, purge_only=true)
  return Ω
end
+(S::SeisData, C::SeisChannel) = +(S, SeisData(C))
+(C::SeisChannel, S::SeisData) = +(S, SeisData(C))
+(C::SeisChannel, D::SeisChannel) = +(SeisData(C), SeisData(D))

# Subtraction
-(S::GphysData, i::Int)          = (U = deepcopy(S); deleteat!(U,i); return U)  # By channel #
-(S::GphysData, J::Array{Int,1}) = (U = deepcopy(S); deleteat!(U,J); return U)  # By array of channel #s

# Multiplication
# distributivity: (S1+S2)*S3) == (S1*S3 + S2*S3)
*(S::SeisData, U::SeisData) = merge(Array{SeisData,1}([S,U]))
*(S::SeisData, C::SeisChannel) = merge(S, SeisData(C))
function *(C::SeisChannel, D::SeisChannel)
  s1 = deepcopy(C)
  s2 = deepcopy(D)
  S = merge(SeisData(s1),SeisData(s2))
  return S
end

# Division will happen eventually; for S/U to be logical, we need to extract
# time ranges of data from S that are not in U. This will work like unix `diff`
