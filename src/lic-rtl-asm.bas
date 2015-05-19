#Include once "lic-rtl.bi"
#Include once "lic-debug.bi"

#if LIC_USE_ASM_FUNCTIONS

function InstrAsm_(ByVal Start As Integer, ByRef TEXT as string, ByVal CHAR as integer) as Integer

  'Written by Mysoft

  asm

    mov EDI,[TEXT]          ' Get String header pointer
    mov ECX,[EDI+4]         ' Get string sz ptr
    xor EAX,EAX             ' clear EAX

    mov EDX,[Start]
    dec EDX
    cmp EDX,ECX
    jge _IAOEndInstr_

    mov ESI,[EDI]           ' Get string text ptr
    mov EBX,[CHAR]          ' CHAR to search :)
    add ESI,EDX             ' Apply Start position to string
    mov EDI,ESI             ' copy of the string start ptr

    Sub ECX,EDX             ' Apply Start position to len
    cmp ECX,4               ' Lenght is less than 4?
    jb _IAOLess4_           ' then skip 4 blocks part...
    mov EDX,ECX             ' copy of counter
    and EDX,(not 3)         ' align in 4 bytes

    _IAONext4Char_:
    mov EAX,[ESI]           'load 4 bytes
    cmp AL,BL               'check byte 4
    je _IAOfound1_          'found?
    shr eax,8               'point byte 3
    cmp AL,BL               'check byte 3
    je _IAOfound2_          'found?
    shr eax,8               'point byte 2
    cmp AL,BL               'check byte 2
    je _IAOfound3_          'found?
    shr eax,8               'point byte 1
    cmp AL,BL               'check byte 1
    jz _IAOfound4_          'found?
    add ESI,4
    sub EDX,4               'go check more 4 bytes
    jnz _IAONext4Char_      'until its done

    xor eax,eax             'clear eax (to not mess with the result)

    _IAOLess4_:
    and ecx,3              'now will check only the last bytes
    jz _IAOEndInstr_       'nothing else to find (so it will be 0)
    cmp [ESI],bl           ' Compare 1
    je _IAOfound1_         ' Is equal? found 1
    dec ecx                ' decrement... finished? 1
    jz _IAOEndInstr_       ' yes then go send result 1
    cmp [ESI+1],bl         ' Compare 2
    je _IAOfound2_         ' Is equal? found 2
    dec ecx                ' decrement... finished? 2
    jz _IAOEndInstr_       ' yes then go send result 2
    cmp [ESI+2],bl         ' Compare 3
    je _IAOfound3_         ' Is equal? found 3
    jmp _IAOEndInstr_      ' not found... (0)

    _IAOfound4_:
    mov EAX,ESI            '  \ Get function result
    sub EAX,EDI            '  / (Actual ptr) - start ptr = result :P
    add EAX,4
    jmp _IAOfound_
    _IAOfound3_:
    mov EAX,ESI            '  \ Get function result
    sub EAX,EDI            '  / (Actual ptr) - start ptr = result :P
    add EAX,3
    jmp _IAOfound_
    _IAOfound2_:
    mov EAX,ESI            '  \ Get function result
    sub EAX,EDI            '  / (Actual ptr) - start ptr = result :P
    add EAX,2
    jmp _IAOfound_
    _IAOfound1_:
    mov EAX,ESI            '  \ Get function result
    sub EAX,EDI            '  / (Actual ptr) - start ptr = result :P
    Inc EAX

    _IAOfound_:
    add EAX, [Start]
    dec EAX

    _IAOEndInstr_:
    mov [function], EAX    ' save result

  end asm

end Function

Function StringEqualAsm_( ByRef Str1 As String, ByRef Str2 As String ) As Integer

  'Written by Mysoft

  asm
    mov EBX,-1
    mov ESI,[STR1]             'Get the pointer to the header of S1
    mov EDI,[STR2]             'Get the pointer to the header of S2
    mov EAX,[ESI+4]            'Get the size of S1
    mov ECX,[EDI+4]            'Get the size of S2
    cmp EAX,ECX                'Compare sizes
    je _ContinueTest_          'They're equal? then continue testing

    _DifferentFlag_:        ' Different strings label
    inc EBX                    'Clear output RESULT
    jmp _EndAsm_               'finish procedure

    _ContinueTest_:         ' Continue testing label
    or ECX,ECX                 'check for both null
    jz _EndAsm_                'Yes? then equal (go finish procedure)
    mov ESI,[ESI]              'Get the string ptr of S1
    mov EDI,[EDI]              'Get the string ptr of S2
    shr ECX,2                  'Get the number of dwords
    jz _LessThanFour_          'Zero? go check byte by byte

    _NextDword_:            ' Label to compare next dword
    cmpsd                      'Compare dwords in ESI/EDI and increment pointers
    jne _DifferentFlag_        'Different? then go finish as different
    dec ECX                    'Decrement dword counter
    jnz _NextDword_            'Go check next dword

    _LessThanFour_:         ' Label to start checking when size <4
    and EAX,3                  'How much bytes? from 0 to 3
    jz _EndAsm_                'no bytes? then end (as equal)

    _NextByte_:             ' Label to check next byte
    cmpsb                      'Compare bytes in ESI/EDI and increment pointers
    jne _DifferentFlag_        'Different? then go finish as different
    dec EAX                    'Decrement byte counter
    jnz _NextByte_             'Go check next byte

    _EndAsm_:               ' End of the asm procedure
    mov [Function],EBX
  end asm

end Function


Function SortCreate( ByRef Key As String ) As uLongInt
   
   dim As ZString * 9 zS
   zS = Key
   
   Asm
      mov eax, [ zS ]            'int1 = *CPtr( integer Ptr, @zS )
      mov ecx, [ zS + 4 ]        'int2 = *CPtr( integer Ptr, @zS + 4 )
      bswap eax                  'reverse the bytes
      bswap ecx
      mov [ Function + 4 ], eax  'Set the high integer
      mov [ Function ], ecx      'Set the low integer
   End Asm

end function

#endif 'LIC_USE_ASM_FUNCTIONS
