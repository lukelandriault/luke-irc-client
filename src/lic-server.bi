Enum CASEMAP
   RFC1459
   STRICT_RFC1459
   ASCII
End Enum

Enum NetworkList
   unknown
   freenode
   efnet
   quakenet
   dalnet
   undernet
   gamesurge
   twitch
End Enum

enum DaemonList
   ratbox = 1
   unreal
   bahamut
   hybrid
End Enum

#Define S_INFO_FLAG_NICKLEN         1
#Define S_INFO_FLAG_CASEMAPPING     1 Shl 1
#Define S_INFO_FLAG_PREFIX          1 Shl 2
#Define S_INFO_FLAG_CHANMODES       1 Shl 3
#Define S_INFO_FLAG_CHANTYPES       1 Shl 4
#Define S_INFO_FLAG_KNOCK           1 Shl 5
