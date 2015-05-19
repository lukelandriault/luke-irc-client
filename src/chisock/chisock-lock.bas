#include "chisock.bi"

namespace chi
	
	constructor socket_lock( byval lock_ as any ptr )
		mutexlock(lock_)
		lock = lock_
	end constructor
	
	destructor socket_lock( )
		mutexunlock(lock)
	end destructor
	
end namespace
