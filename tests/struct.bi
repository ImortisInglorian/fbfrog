'' type T : ... : end type
'' type as T A
'' (Both ids might be needed)
type T
	as integer a
end type : type as T A

'' Anonymous struct typedef
'' type TT : ... : end type
type TT
	as integer a
end type

'' Anonymous struct typedef triggering the fake id insertion
type __FAKE__ /' TODO: added fake id for anonymous struct '/
	as integer a
end type : type as __FAKE__ A : type as __FAKE__ ptr PA

'' type T : ... : end type
'' type as T A, B : type as T ptr C : type as function() as T D
type T
	as integer a
end type : type as T A, B : type as T ptr C : type as function() as T D

'' type T : ... : end type
'' (also, any places using <struct T> will become just <T>, so they work ok)
type T
	as integer a
end type

type T : as integer a : end type

type T : as integer a : end type