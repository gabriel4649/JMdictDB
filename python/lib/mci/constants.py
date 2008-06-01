# Media Control Interface (MCI) constant declarations
# from Microsoft Window's MMSYSTEM.H
# (in c:\program files\microsoft visual studio\VC98\Include\)
# These were taken from MSVS-6.0sp5 on Windows 2000.
# $Id$

DRV_RESERVED                    = 0x0800
DRV_MCI_FIRST                   = DRV_RESERVED
DRV_MCI_LAST                    = (DRV_RESERVED + 0xFFF)
MCI_STRING_OFFSET      		= 512
MCI_VD_OFFSET          		= 1024
MCI_CD_OFFSET          		= 1088
MCI_WAVE_OFFSET        		= 1152
MCI_SEQ_OFFSET         		= 1216
MCIERR_BASE                     = 256

# MCI error return values 
MCIERR_INVALID_DEVICE_ID        = (MCIERR_BASE + 1)
MCIERR_UNRECOGNIZED_KEYWORD     = (MCIERR_BASE + 3)
MCIERR_UNRECOGNIZED_COMMAND     = (MCIERR_BASE + 5)
MCIERR_HARDWARE                 = (MCIERR_BASE + 6)
MCIERR_INVALID_DEVICE_NAME      = (MCIERR_BASE + 7)
MCIERR_OUT_OF_MEMORY            = (MCIERR_BASE + 8)
MCIERR_DEVICE_OPEN              = (MCIERR_BASE + 9)
MCIERR_CANNOT_LOAD_DRIVER       = (MCIERR_BASE + 10)
MCIERR_MISSING_COMMAND_STRING   = (MCIERR_BASE + 11)
MCIERR_PARAM_OVERFLOW           = (MCIERR_BASE + 12)
MCIERR_MISSING_STRING_ARGUMENT  = (MCIERR_BASE + 13)
MCIERR_BAD_INTEGER              = (MCIERR_BASE + 14)
MCIERR_PARSER_INTERNAL          = (MCIERR_BASE + 15)
MCIERR_DRIVER_INTERNAL          = (MCIERR_BASE + 16)
MCIERR_MISSING_PARAMETER        = (MCIERR_BASE + 17)
MCIERR_UNSUPPORTED_FUNCTION     = (MCIERR_BASE + 18)
MCIERR_FILE_NOT_FOUND           = (MCIERR_BASE + 19)
MCIERR_DEVICE_NOT_READY         = (MCIERR_BASE + 20)
MCIERR_INTERNAL                 = (MCIERR_BASE + 21)
MCIERR_DRIVER                   = (MCIERR_BASE + 22)
MCIERR_CANNOT_USE_ALL           = (MCIERR_BASE + 23)
MCIERR_MULTIPLE                 = (MCIERR_BASE + 24)
MCIERR_EXTENSION_NOT_FOUND      = (MCIERR_BASE + 25)
MCIERR_OUTOFRANGE               = (MCIERR_BASE + 26)
MCIERR_FLAGS_NOT_COMPATIBLE     = (MCIERR_BASE + 28)
MCIERR_FILE_NOT_SAVED           = (MCIERR_BASE + 30)
MCIERR_DEVICE_TYPE_REQUIRED     = (MCIERR_BASE + 31)
MCIERR_DEVICE_LOCKED            = (MCIERR_BASE + 32)
MCIERR_DUPLICATE_ALIAS          = (MCIERR_BASE + 33)
MCIERR_BAD_CONSTANT             = (MCIERR_BASE + 34)
MCIERR_MUST_USE_SHAREABLE       = (MCIERR_BASE + 35)
MCIERR_MISSING_DEVICE_NAME      = (MCIERR_BASE + 36)
MCIERR_BAD_TIME_FORMAT          = (MCIERR_BASE + 37)
MCIERR_NO_CLOSING_QUOTE         = (MCIERR_BASE + 38)
MCIERR_DUPLICATE_FLAGS          = (MCIERR_BASE + 39)
MCIERR_INVALID_FILE             = (MCIERR_BASE + 40)
MCIERR_NULL_PARAMETER_BLOCK     = (MCIERR_BASE + 41)
MCIERR_UNNAMED_RESOURCE         = (MCIERR_BASE + 42)
MCIERR_NEW_REQUIRES_ALIAS       = (MCIERR_BASE + 43)
MCIERR_NOTIFY_ON_AUTO_OPEN      = (MCIERR_BASE + 44)
MCIERR_NO_ELEMENT_ALLOWED       = (MCIERR_BASE + 45)
MCIERR_NONAPPLICABLE_FUNCTION   = (MCIERR_BASE + 46)
MCIERR_ILLEGAL_FOR_AUTO_OPEN    = (MCIERR_BASE + 47)
MCIERR_FILENAME_REQUIRED        = (MCIERR_BASE + 48)
MCIERR_EXTRA_CHARACTERS         = (MCIERR_BASE + 49)
MCIERR_DEVICE_NOT_INSTALLED     = (MCIERR_BASE + 50)
MCIERR_GET_CD                   = (MCIERR_BASE + 51)
MCIERR_SET_CD                   = (MCIERR_BASE + 52)
MCIERR_SET_DRIVE                = (MCIERR_BASE + 53)
MCIERR_DEVICE_LENGTH            = (MCIERR_BASE + 54)
MCIERR_DEVICE_ORD_LENGTH        = (MCIERR_BASE + 55)
MCIERR_NO_INTEGER               = (MCIERR_BASE + 56)

MCIERR_WAVE_OUTPUTSINUSE        = (MCIERR_BASE + 64)
MCIERR_WAVE_SETOUTPUTINUSE      = (MCIERR_BASE + 65)
MCIERR_WAVE_INPUTSINUSE         = (MCIERR_BASE + 66)
MCIERR_WAVE_SETINPUTINUSE       = (MCIERR_BASE + 67)
MCIERR_WAVE_OUTPUTUNSPECIFIED   = (MCIERR_BASE + 68)
MCIERR_WAVE_INPUTUNSPECIFIED    = (MCIERR_BASE + 69)
MCIERR_WAVE_OUTPUTSUNSUITABLE   = (MCIERR_BASE + 70)
MCIERR_WAVE_SETOUTPUTUNSUITABLE = (MCIERR_BASE + 71)
MCIERR_WAVE_INPUTSUNSUITABLE    = (MCIERR_BASE + 72)
MCIERR_WAVE_SETINPUTUNSUITABLE  = (MCIERR_BASE + 73)

MCIERR_SEQ_DIV_INCOMPATIBLE     = (MCIERR_BASE + 80)
MCIERR_SEQ_PORT_INUSE           = (MCIERR_BASE + 81)
MCIERR_SEQ_PORT_NONEXISTENT     = (MCIERR_BASE + 82)
MCIERR_SEQ_PORT_MAPNODEVICE     = (MCIERR_BASE + 83)
MCIERR_SEQ_PORT_MISCERROR       = (MCIERR_BASE + 84)
MCIERR_SEQ_TIMER                = (MCIERR_BASE + 85)
MCIERR_SEQ_PORTUNSPECIFIED      = (MCIERR_BASE + 86)
MCIERR_SEQ_NOMIDIPRESENT        = (MCIERR_BASE + 87)

MCIERR_NO_WINDOW                = (MCIERR_BASE + 90)
MCIERR_CREATEWINDOW             = (MCIERR_BASE + 91)
MCIERR_FILE_READ                = (MCIERR_BASE + 92)
MCIERR_FILE_WRITE               = (MCIERR_BASE + 93)

MCIERR_NO_IDENTITY              = (MCIERR_BASE + 94)

# all custom device driver errors must be >= than this value 
MCIERR_CUSTOM_DRIVER_BASE       = (MCIERR_BASE + 256)

MCI_FIRST                       = DRV_MCI_FIRST   # 0x0800 
# MCI command message identifiers 
MCI_OPEN                        = 0x0803
MCI_CLOSE                       = 0x0804
MCI_ESCAPE                      = 0x0805
MCI_PLAY                        = 0x0806
MCI_SEEK                        = 0x0807
MCI_STOP                        = 0x0808
MCI_PAUSE                       = 0x0809
MCI_INFO                        = 0x080A
MCI_GETDEVCAPS                  = 0x080B
MCI_SPIN                        = 0x080C
MCI_SET                         = 0x080D
MCI_STEP                        = 0x080E
MCI_RECORD                      = 0x080F
MCI_SYSINFO                     = 0x0810
MCI_BREAK                       = 0x0811
MCI_SAVE                        = 0x0813
MCI_STATUS                      = 0x0814
MCI_CUE                         = 0x0830
MCI_REALIZE                     = 0x0840
MCI_WINDOW                      = 0x0841
MCI_PUT                         = 0x0842
MCI_WHERE                       = 0x0843
MCI_FREEZE                      = 0x0844
MCI_UNFREEZE                    = 0x0845
MCI_LOAD                        = 0x0850
MCI_CUT                         = 0x0851
MCI_COPY                        = 0x0852
MCI_PASTE                       = 0x0853
MCI_UPDATE                      = 0x0854
MCI_RESUME                      = 0x0855
MCI_DELETE                      = 0x0856

# all custom MCI command messages must be >= than this value 
MCI_USER_MESSAGES               = (DRV_MCI_FIRST + 0x400)
MCI_LAST                        = 0x0FFF

# device ID for "all devices" 
MCI_ALL_DEVICE_ID               = -1

# constants for predefined MCI device types 
MCI_DEVTYPE_VCR                 = 513 # (MCI_STRING_OFFSET + 1) 
MCI_DEVTYPE_VIDEODISC           = 514 # (MCI_STRING_OFFSET + 2) 
MCI_DEVTYPE_OVERLAY             = 515 # (MCI_STRING_OFFSET + 3) 
MCI_DEVTYPE_CD_AUDIO            = 516 # (MCI_STRING_OFFSET + 4) 
MCI_DEVTYPE_DAT                 = 517 # (MCI_STRING_OFFSET + 5) 
MCI_DEVTYPE_SCANNER             = 518 # (MCI_STRING_OFFSET + 6) 
MCI_DEVTYPE_ANIMATION           = 519 # (MCI_STRING_OFFSET + 7) 
MCI_DEVTYPE_DIGITAL_VIDEO       = 520 # (MCI_STRING_OFFSET + 8) 
MCI_DEVTYPE_OTHER               = 521 # (MCI_STRING_OFFSET + 9) 
MCI_DEVTYPE_WAVEFORM_AUDIO      = 522 # (MCI_STRING_OFFSET + 10) 
MCI_DEVTYPE_SEQUENCER           = 523 # (MCI_STRING_OFFSET + 11) 

MCI_DEVTYPE_FIRST               = MCI_DEVTYPE_VCR
MCI_DEVTYPE_LAST                = MCI_DEVTYPE_SEQUENCER

MCI_DEVTYPE_FIRST_USER          = 0x1000
# return values for 'status mode' command 
MCI_MODE_NOT_READY              = (MCI_STRING_OFFSET + 12)
MCI_MODE_STOP                   = (MCI_STRING_OFFSET + 13)
MCI_MODE_PLAY                   = (MCI_STRING_OFFSET + 14)
MCI_MODE_RECORD                 = (MCI_STRING_OFFSET + 15)
MCI_MODE_SEEK                   = (MCI_STRING_OFFSET + 16)
MCI_MODE_PAUSE                  = (MCI_STRING_OFFSET + 17)
MCI_MODE_OPEN                   = (MCI_STRING_OFFSET + 18)

# constants used in 'set time format' and 'status time format' commands 
MCI_FORMAT_MILLISECONDS         = 0
MCI_FORMAT_HMS                  = 1
MCI_FORMAT_MSF                  = 2
MCI_FORMAT_FRAMES               = 3
MCI_FORMAT_SMPTE_24             = 4
MCI_FORMAT_SMPTE_25             = 5
MCI_FORMAT_SMPTE_30             = 6
MCI_FORMAT_SMPTE_30DROP         = 7
MCI_FORMAT_BYTES                = 8
MCI_FORMAT_SAMPLES              = 9
MCI_FORMAT_TMSF                 = 10

# Following are included as comments for reference...
# MCI time format conversion macros 
#define MCI_MSF_MINUTE(msf)             ((BYTE)(msf))
#define MCI_MSF_SECOND(msf)             ((BYTE)(((WORD)(msf)) >> 8))
#define MCI_MSF_FRAME(msf)              ((BYTE)((msf)>>16))
#define MCI_MAKE_MSF(m, s, f)           ((DWORD)(((BYTE)(m) | \
#					  ((WORD)(s)<<8)) | \
#					  (((DWORD)(BYTE)(f))<<16)))
#define MCI_TMSF_TRACK(tmsf)            ((BYTE)(tmsf))
#define MCI_TMSF_MINUTE(tmsf)           ((BYTE)(((WORD)(tmsf)) >> 8))
#define MCI_TMSF_SECOND(tmsf)           ((BYTE)((tmsf)>>16))
#define MCI_TMSF_FRAME(tmsf)            ((BYTE)((tmsf)>>24))
#define MCI_MAKE_TMSF(t, m, s, f)       ((DWORD)(((BYTE)(t) | \
#					  ((WORD)(m)<<8)) | \
#					  (((DWORD)(BYTE)(s) | \
#					  ((WORD)(f)<<8))<<16)))
#define MCI_HMS_HOUR(hms)               ((BYTE)(hms))
#define MCI_HMS_MINUTE(hms)             ((BYTE)(((WORD)(hms)) >> 8))
#define MCI_HMS_SECOND(hms)             ((BYTE)((hms)>>16))
#define MCI_MAKE_HMS(h, m, s)           ((DWORD)(((BYTE)(h) | \
#					  ((WORD)(m)<<8)) | \
#					  (((DWORD)(BYTE)(s))<<16)))

# flags for wParam of MM_MCINOTIFY message 
MCI_NOTIFY_SUCCESSFUL           = 0x0001
MCI_NOTIFY_SUPERSEDED           = 0x0002
MCI_NOTIFY_ABORTED              = 0x0004
MCI_NOTIFY_FAILURE              = 0x0008

# common flags for dwFlags parameter of MCI command messages 
MCI_NOTIFY                      = 0x00000001
MCI_WAIT                        = 0x00000002
MCI_FROM                        = 0x00000004
MCI_TO                          = 0x00000008
MCI_TRACK                       = 0x00000010

# flags for dwFlags parameter of MCI_OPEN command message 
MCI_OPEN_SHAREABLE              = 0x00000100
MCI_OPEN_ELEMENT                = 0x00000200
MCI_OPEN_ALIAS                  = 0x00000400
MCI_OPEN_ELEMENT_ID             = 0x00000800
MCI_OPEN_TYPE_ID                = 0x00001000
MCI_OPEN_TYPE                   = 0x00002000

# flags for dwFlags parameter of MCI_SEEK command message 
MCI_SEEK_TO_START               = 0x00000100
MCI_SEEK_TO_END                 = 0x00000200

# flags for dwFlags parameter of MCI_STATUS command message 
MCI_STATUS_ITEM                 = 0x00000100
MCI_STATUS_START                = 0x00000200

# flags for dwItem field of the MCI_STATUS_PARMS parameter block 
MCI_STATUS_LENGTH               = 0x00000001
MCI_STATUS_POSITION             = 0x00000002
MCI_STATUS_NUMBER_OF_TRACKS     = 0x00000003
MCI_STATUS_MODE                 = 0x00000004
MCI_STATUS_MEDIA_PRESENT        = 0x00000005
MCI_STATUS_TIME_FORMAT          = 0x00000006
MCI_STATUS_READY                = 0x00000007
MCI_STATUS_CURRENT_TRACK        = 0x00000008

# flags for dwFlags parameter of MCI_INFO command message 
MCI_INFO_PRODUCT                = 0x00000100
MCI_INFO_FILE                   = 0x00000200
MCI_INFO_MEDIA_UPC              = 0x00000400
MCI_INFO_MEDIA_IDENTITY         = 0x00000800
MCI_INFO_NAME                   = 0x00001000
MCI_INFO_COPYRIGHT              = 0x00002000

# flags for dwFlags parameter of MCI_GETDEVCAPS command message 
MCI_GETDEVCAPS_ITEM             = 0x00000100

# flags for dwItem field of the MCI_GETDEVCAPS_PARMS parameter block 
MCI_GETDEVCAPS_CAN_RECORD       = 0x00000001
MCI_GETDEVCAPS_HAS_AUDIO        = 0x00000002
MCI_GETDEVCAPS_HAS_VIDEO        = 0x00000003
MCI_GETDEVCAPS_DEVICE_TYPE      = 0x00000004
MCI_GETDEVCAPS_USES_FILES       = 0x00000005
MCI_GETDEVCAPS_COMPOUND_DEVICE  = 0x00000006
MCI_GETDEVCAPS_CAN_EJECT        = 0x00000007
MCI_GETDEVCAPS_CAN_PLAY         = 0x00000008
MCI_GETDEVCAPS_CAN_SAVE         = 0x00000009

# flags for dwFlags parameter of MCI_SYSINFO command message 
MCI_SYSINFO_QUANTITY            = 0x00000100
MCI_SYSINFO_OPEN                = 0x00000200
MCI_SYSINFO_NAME                = 0x00000400
MCI_SYSINFO_INSTALLNAME         = 0x00000800

# flags for dwFlags parameter of MCI_SET command message 
MCI_SET_DOOR_OPEN               = 0x00000100
MCI_SET_DOOR_CLOSED             = 0x00000200
MCI_SET_TIME_FORMAT             = 0x00000400
MCI_SET_AUDIO                   = 0x00000800
MCI_SET_VIDEO                   = 0x00001000
MCI_SET_ON                      = 0x00002000
MCI_SET_OFF                     = 0x00004000

# flags for dwAudio field of MCI_SET_PARMS or MCI_SEQ_SET_PARMS 
MCI_SET_AUDIO_ALL               = 0x00000000
MCI_SET_AUDIO_LEFT              = 0x00000001
MCI_SET_AUDIO_RIGHT             = 0x00000002

# flags for dwFlags parameter of MCI_BREAK command message 
MCI_BREAK_KEY                   = 0x00000100
MCI_BREAK_HWND                  = 0x00000200
MCI_BREAK_OFF                   = 0x00000400

# flags for dwFlags parameter of MCI_RECORD command message 
MCI_RECORD_INSERT               = 0x00000100
MCI_RECORD_OVERWRITE            = 0x00000200

# flags for dwFlags parameter of MCI_SAVE command message 
MCI_SAVE_FILE                   = 0x00000100

# flags for dwFlags parameter of MCI_LOAD command message 
MCI_LOAD_FILE                   = 0x00000100

# generic parameter block for MCI command messages with no special parameters 
# parameter block for MCI_OPEN command message 
# parameter block for MCI_PLAY command message 
# parameter block for MCI_SEEK command message 
# parameter block for MCI_STATUS command message 
# parameter block for MCI_INFO command message 
# parameter block for MCI_GETDEVCAPS command message 
# parameter block for MCI_SYSINFO command message 
# parameter block for MCI_SET command message 
# parameter block for MCI_BREAK command message 
# parameter block for MCI_SAVE command message 
# parameter block for MCI_LOAD command message 
# parameter block for MCI_RECORD command message 
# MCI extensions for videodisc devices 

# flag for dwReturn field of MCI_STATUS_PARMS 
# MCI_STATUS command, (dwItem == MCI_STATUS_MODE) 
MCI_VD_MODE_PARK                = (MCI_VD_OFFSET + 1)

# flag for dwReturn field of MCI_STATUS_PARMS 
# MCI_STATUS command, (dwItem == MCI_VD_STATUS_MEDIA_TYPE) 
MCI_VD_MEDIA_CLV                = (MCI_VD_OFFSET + 2)
MCI_VD_MEDIA_CAV                = (MCI_VD_OFFSET + 3)
MCI_VD_MEDIA_OTHER              = (MCI_VD_OFFSET + 4)

MCI_VD_FORMAT_TRACK             = 0x4001

# flags for dwFlags parameter of MCI_PLAY command message 
MCI_VD_PLAY_REVERSE             = 0x00010000
MCI_VD_PLAY_FAST                = 0x00020000
MCI_VD_PLAY_SPEED               = 0x00040000
MCI_VD_PLAY_SCAN                = 0x00080000
MCI_VD_PLAY_SLOW                = 0x00100000

# flag for dwFlags parameter of MCI_SEEK command message 
MCI_VD_SEEK_REVERSE             = 0x00010000

# flags for dwItem field of MCI_STATUS_PARMS parameter block 
MCI_VD_STATUS_SPEED             = 0x00004002
MCI_VD_STATUS_FORWARD           = 0x00004003
MCI_VD_STATUS_MEDIA_TYPE        = 0x00004004
MCI_VD_STATUS_SIDE              = 0x00004005
MCI_VD_STATUS_DISC_SIZE         = 0x00004006

# flags for dwFlags parameter of MCI_GETDEVCAPS command message 
MCI_VD_GETDEVCAPS_CLV           = 0x00010000
MCI_VD_GETDEVCAPS_CAV           = 0x00020000

MCI_VD_SPIN_UP                  = 0x00010000
MCI_VD_SPIN_DOWN                = 0x00020000

# flags for dwItem field of MCI_GETDEVCAPS_PARMS parameter block 
MCI_VD_GETDEVCAPS_CAN_REVERSE   = 0x00004002
MCI_VD_GETDEVCAPS_FAST_RATE     = 0x00004003
MCI_VD_GETDEVCAPS_SLOW_RATE     = 0x00004004
MCI_VD_GETDEVCAPS_NORMAL_RATE   = 0x00004005

# flags for the dwFlags parameter of MCI_STEP command message 
MCI_VD_STEP_FRAMES              = 0x00010000
MCI_VD_STEP_REVERSE             = 0x00020000

# flag for the MCI_ESCAPE command message 
MCI_VD_ESCAPE_STRING            = 0x00000100

# parameter block for MCI_PLAY command message 
# parameter block for MCI_STEP command message 
# parameter block for MCI_ESCAPE command message 
# MCI extensions for CD audio devices 

# flags for the dwItem field of the MCI_STATUS_PARMS parameter block 
MCI_CDA_STATUS_TYPE_TRACK       = 0x00004001

# flags for the dwReturn field of MCI_STATUS_PARMS parameter block 
# MCI_STATUS command, (dwItem == MCI_CDA_STATUS_TYPE_TRACK) 
MCI_CDA_TRACK_AUDIO             = (MCI_CD_OFFSET + 0)
MCI_CDA_TRACK_OTHER             = (MCI_CD_OFFSET + 1)

# MCI extensions for waveform audio devices 

MCI_WAVE_PCM                    = (MCI_WAVE_OFFSET + 0)
MCI_WAVE_MAPPER                 = (MCI_WAVE_OFFSET + 1)

# flags for the dwFlags parameter of MCI_OPEN command message 
MCI_WAVE_OPEN_BUFFER            = 0x00010000

# flags for the dwFlags parameter of MCI_SET command message 
MCI_WAVE_SET_FORMATTAG          = 0x00010000
MCI_WAVE_SET_CHANNELS           = 0x00020000
MCI_WAVE_SET_SAMPLESPERSEC      = 0x00040000
MCI_WAVE_SET_AVGBYTESPERSEC     = 0x00080000
MCI_WAVE_SET_BLOCKALIGN         = 0x00100000
MCI_WAVE_SET_BITSPERSAMPLE      = 0x00200000

# flags for the dwFlags parameter of MCI_STATUS, MCI_SET command messages 
MCI_WAVE_INPUT                  = 0x00400000
MCI_WAVE_OUTPUT                 = 0x00800000

# flags for the dwItem field of MCI_STATUS_PARMS parameter block 
MCI_WAVE_STATUS_FORMATTAG       = 0x00004001
MCI_WAVE_STATUS_CHANNELS        = 0x00004002
MCI_WAVE_STATUS_SAMPLESPERSEC   = 0x00004003
MCI_WAVE_STATUS_AVGBYTESPERSEC  = 0x00004004
MCI_WAVE_STATUS_BLOCKALIGN      = 0x00004005
MCI_WAVE_STATUS_BITSPERSAMPLE   = 0x00004006
MCI_WAVE_STATUS_LEVEL           = 0x00004007

# flags for the dwFlags parameter of MCI_SET command message 
MCI_WAVE_SET_ANYINPUT           = 0x04000000
MCI_WAVE_SET_ANYOUTPUT          = 0x08000000

# flags for the dwFlags parameter of MCI_GETDEVCAPS command message 
MCI_WAVE_GETDEVCAPS_INPUTS      = 0x00004001
MCI_WAVE_GETDEVCAPS_OUTPUTS     = 0x00004002

# parameter block for MCI_OPEN command message 

# parameter block for MCI_DELETE command message 
# parameter block for MCI_SET command message 
# MCI extensions for MIDI sequencer devices 

# flags for the dwReturn field of MCI_STATUS_PARMS parameter block 
# MCI_STATUS command, (dwItem == MCI_SEQ_STATUS_DIVTYPE) 
MCI_SEQ_DIV_PPQN                = (0 + MCI_SEQ_OFFSET)
MCI_SEQ_DIV_SMPTE_24            = (1 + MCI_SEQ_OFFSET)
MCI_SEQ_DIV_SMPTE_25            = (2 + MCI_SEQ_OFFSET)
MCI_SEQ_DIV_SMPTE_30DROP        = (3 + MCI_SEQ_OFFSET)
MCI_SEQ_DIV_SMPTE_30            = (4 + MCI_SEQ_OFFSET)

# flags for the dwMaster field of MCI_SEQ_SET_PARMS parameter block 
# MCI_SET command, (dwFlags == MCI_SEQ_SET_MASTER) 
MCI_SEQ_FORMAT_SONGPTR          = 0x4001
MCI_SEQ_FILE                    = 0x4002
MCI_SEQ_MIDI                    = 0x4003
MCI_SEQ_SMPTE                   = 0x4004
MCI_SEQ_NONE                    = 65533
MCI_SEQ_MAPPER                  = 65535

# flags for the dwItem field of MCI_STATUS_PARMS parameter block 
MCI_SEQ_STATUS_TEMPO            = 0x00004002
MCI_SEQ_STATUS_PORT             = 0x00004003
MCI_SEQ_STATUS_SLAVE            = 0x00004007
MCI_SEQ_STATUS_MASTER           = 0x00004008
MCI_SEQ_STATUS_OFFSET           = 0x00004009
MCI_SEQ_STATUS_DIVTYPE          = 0x0000400A
MCI_SEQ_STATUS_NAME             = 0x0000400B
MCI_SEQ_STATUS_COPYRIGHT        = 0x0000400C

# flags for the dwFlags parameter of MCI_SET command message 
MCI_SEQ_SET_TEMPO               = 0x00010000
MCI_SEQ_SET_PORT                = 0x00020000
MCI_SEQ_SET_SLAVE               = 0x00040000
MCI_SEQ_SET_MASTER              = 0x00080000
MCI_SEQ_SET_OFFSET              = 0x01000000

# parameter block for MCI_SET command message 

# MCI extensions for animation devices 

# flags for dwFlags parameter of MCI_OPEN command message 
MCI_ANIM_OPEN_WS                = 0x00010000
MCI_ANIM_OPEN_PARENT            = 0x00020000
MCI_ANIM_OPEN_NOSTATIC          = 0x00040000

# flags for dwFlags parameter of MCI_PLAY command message 
MCI_ANIM_PLAY_SPEED             = 0x00010000
MCI_ANIM_PLAY_REVERSE           = 0x00020000
MCI_ANIM_PLAY_FAST              = 0x00040000
MCI_ANIM_PLAY_SLOW              = 0x00080000
MCI_ANIM_PLAY_SCAN              = 0x00100000

# flags for dwFlags parameter of MCI_STEP command message 
MCI_ANIM_STEP_REVERSE           = 0x00010000
MCI_ANIM_STEP_FRAMES            = 0x00020000

# flags for dwItem field of MCI_STATUS_PARMS parameter block 
MCI_ANIM_STATUS_SPEED           = 0x00004001
MCI_ANIM_STATUS_FORWARD         = 0x00004002
MCI_ANIM_STATUS_HWND            = 0x00004003
MCI_ANIM_STATUS_HPAL            = 0x00004004
MCI_ANIM_STATUS_STRETCH         = 0x00004005

# flags for the dwFlags parameter of MCI_INFO command message 
MCI_ANIM_INFO_TEXT              = 0x00010000

# flags for dwItem field of MCI_GETDEVCAPS_PARMS parameter block 
MCI_ANIM_GETDEVCAPS_CAN_REVERSE = 0x00004001
MCI_ANIM_GETDEVCAPS_FAST_RATE   = 0x00004002
MCI_ANIM_GETDEVCAPS_SLOW_RATE   = 0x00004003
MCI_ANIM_GETDEVCAPS_NORMAL_RATE = 0x00004004
MCI_ANIM_GETDEVCAPS_PALETTES    = 0x00004006
MCI_ANIM_GETDEVCAPS_CAN_STRETCH = 0x00004007
MCI_ANIM_GETDEVCAPS_MAX_WINDOWS = 0x00004008

# flags for the MCI_REALIZE command message 
MCI_ANIM_REALIZE_NORM           = 0x00010000
MCI_ANIM_REALIZE_BKGD           = 0x00020000

# flags for dwFlags parameter of MCI_WINDOW command message 
MCI_ANIM_WINDOW_HWND            = 0x00010000
MCI_ANIM_WINDOW_STATE           = 0x00040000
MCI_ANIM_WINDOW_TEXT            = 0x00080000
MCI_ANIM_WINDOW_ENABLE_STRETCH  = 0x00100000
MCI_ANIM_WINDOW_DISABLE_STRETCH = 0x00200000

# flags for hWnd field of MCI_ANIM_WINDOW_PARMS parameter block 
# MCI_WINDOW command message, (dwFlags == MCI_ANIM_WINDOW_HWND) 
MCI_ANIM_WINDOW_DEFAULT         = 0x00000000

# flags for dwFlags parameter of MCI_PUT command message 
MCI_ANIM_RECT                   = 0x00010000
MCI_ANIM_PUT_SOURCE             = 0x00020000
MCI_ANIM_PUT_DESTINATION        = 0x00040000

# flags for dwFlags parameter of MCI_WHERE command message 
MCI_ANIM_WHERE_SOURCE           = 0x00020000
MCI_ANIM_WHERE_DESTINATION      = 0x00040000

# flags for dwFlags parameter of MCI_UPDATE command message 
MCI_ANIM_UPDATE_HDC             = 0x00020000

# parameter block for MCI_OPEN command message 

# parameter block for MCI_PUT, MCI_UPDATE, MCI_WHERE command messages 
# parameter block for MCI_UPDATE PARMS 
# MCI extensions for video overlay devices 

# flags for dwFlags parameter of MCI_OPEN command message 
MCI_OVLY_OPEN_WS                = 0x00010000
MCI_OVLY_OPEN_PARENT            = 0x00020000

# flags for dwFlags parameter of MCI_STATUS command message 
MCI_OVLY_STATUS_HWND            = 0x00004001
MCI_OVLY_STATUS_STRETCH         = 0x00004002

# flags for dwFlags parameter of MCI_INFO command message 
MCI_OVLY_INFO_TEXT              = 0x00010000

# flags for dwItem field of MCI_GETDEVCAPS_PARMS parameter block 
MCI_OVLY_GETDEVCAPS_CAN_STRETCH = 0x00004001
MCI_OVLY_GETDEVCAPS_CAN_FREEZE  = 0x00004002
MCI_OVLY_GETDEVCAPS_MAX_WINDOWS = 0x00004003

# flags for dwFlags parameter of MCI_WINDOW command message 
MCI_OVLY_WINDOW_HWND            = 0x00010000
MCI_OVLY_WINDOW_STATE           = 0x00040000
MCI_OVLY_WINDOW_TEXT            = 0x00080000
MCI_OVLY_WINDOW_ENABLE_STRETCH  = 0x00100000
MCI_OVLY_WINDOW_DISABLE_STRETCH = 0x00200000

# flags for hWnd parameter of MCI_OVLY_WINDOW_PARMS parameter block 
MCI_OVLY_WINDOW_DEFAULT         = 0x00000000

# flags for dwFlags parameter of MCI_PUT command message 
MCI_OVLY_RECT                   = 0x00010000
MCI_OVLY_PUT_SOURCE             = 0x00020000
MCI_OVLY_PUT_DESTINATION        = 0x00040000
MCI_OVLY_PUT_FRAME              = 0x00080000
MCI_OVLY_PUT_VIDEO              = 0x00100000

# flags for dwFlags parameter of MCI_WHERE command message 
MCI_OVLY_WHERE_SOURCE           = 0x00020000
MCI_OVLY_WHERE_DESTINATION      = 0x00040000
MCI_OVLY_WHERE_FRAME            = 0x00080000
MCI_OVLY_WHERE_VIDEO            = 0x00100000

# parameter block for MCI_OPEN command message 

# parameter block for MCI_WINDOW command message 

# parameter block for MCI_PUT, MCI_UPDATE, and MCI_WHERE command messages 

# parameter block for MCI_SAVE command message 

# parameter block for MCI_LOAD command message 
