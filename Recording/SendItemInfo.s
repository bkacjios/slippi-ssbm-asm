# constants
.set  CMD_ITEM,0x3B

# struct offsets
.set  OFST_CMD,0x0
.set  OFST_FRAME,OFST_CMD+0x1
.set  OFST_ID,OFST_FRAME+0x4
.set  OFST_STATE,OFST_ID+0x2
.set  OFST_DIRECTION,OFST_STATE+0x1
.set  OFST_XVELOCITY,OFST_DIRECTION+0x4
.set  OFST_YVELOCITY,OFST_XVELOCITY+0x4
.set  OFST_XPOS,OFST_YVELOCITY+0x4
.set  OFST_YPOS,OFST_XPOS+0x4
.set  OFST_DMGTAKEN,OFST_YPOS+0x4
.set  OFST_EXPIRETIME,OFST_DMGTAKEN+0x2
.set  ITEM_STRUCT_SIZE,OFST_EXPIRETIME+0x2

.macro Macro_SendItemInfo

CreateItemInfoProc:
#Create GObj
  li	r3,4	    	#GObj Type (4 is the player type, this should ensure it runs before any player animations)
  li	r4,7	  	  #On-Pause Function (dont run on pause)
  li	r5,0        #some type of priority
  branchl	r12,GObj_Create

#Create Proc
  bl  SendItemInfo
  mflr r4         #Function
  li  r5,15        #Priority
  branchl	r12,GObj_AddProc

b CreateItemInfo_Exit

################################################################################
# Routine: SendItemInfo
# ------------------------------------------------------------------------------
# Description: Sends data about each active item
################################################################################

SendItemInfo:
blrl

.set REG_Buffer,31
.set REG_BufferOffset,30
.set REG_ItemGObj,29
.set REG_ItemData,28
.set REG_ItemCount,27

backup

#------------- INITIALIZE -------------
# here we want to initalize some variables we plan on using throughout
# get current offset in buffer
  lwz REG_Buffer,frameDataBuffer(r13)
  lwz REG_BufferOffset,bufferOffset(r13)
  add REG_Buffer,REG_Buffer,REG_BufferOffset
  li  REG_ItemCount,0

# get first created item
  lwz r3,-0x3E74 (r13)
  lwz REG_ItemGObj,0x24(r3)
  cmpwi REG_ItemGObj,0
  beq SendItemInfo_Exit

SendItemInfo_AddToBuffer:
# check if exceeds item limit
  addi  REG_ItemCount,REG_ItemCount,1
  cmpwi REG_ItemCount,MAX_ITEMS
  bgt SendItemInfo_Exit

# get item data
  lwz REG_ItemData,0x2C(REG_ItemGObj)

# check if blacklisted item

# send data
# initial RNG command byte
  li r3, CMD_ITEM
  stb r3,OFST_CMD(REG_Buffer)
# send frame count
  lwz r3,frameIndex(r13)
  stw r3,OFST_FRAME(REG_Buffer)
# store item ID
  lwz r3,0x10(REG_ItemData)
  sth r3,OFST_ID(REG_Buffer)
# store item state
  lwz r3,0x24(REG_ItemData)
  stb r3,OFST_STATE(REG_Buffer)
# store item direction
  lwz r3,0x2C(REG_ItemData)
  stw r3,OFST_DIRECTION(REG_Buffer)
# store item XVel
  lwz r3,0x40(REG_ItemData)
  stw r3,OFST_XVELOCITY(REG_Buffer)
# store item YVel
  lwz r3,0x44(REG_ItemData)
  stw r3,OFST_YVELOCITY(REG_Buffer)
# store item XPos
  lwz r3,0x4C(REG_ItemData)
  stw r3,OFST_XPOS(REG_Buffer)
# store item YPos
  lwz r3,0x50(REG_ItemData)
  stw r3,OFST_YPOS(REG_Buffer)
# store item damage taken
  lwz r3,0xC9C(REG_ItemData)
  sth r3,OFST_DMGTAKEN(REG_Buffer)
# store item expiration
  lwz r3,0xD44(REG_ItemData)
  sth r3,OFST_EXPIRETIME(REG_Buffer)
#------------- Increment Buffer Offset ------------
  lwz REG_BufferOffset,bufferOffset(r13)
  addi REG_BufferOffset,REG_BufferOffset, ITEM_STRUCT_SIZE
  stw REG_BufferOffset,bufferOffset(r13)

SendItemInfo_GetNextItem:
# get next item
  lwz REG_ItemGObj,0x8(REG_ItemGObj)
  cmpwi REG_ItemGObj,0
  bne SendItemInfo_AddToBuffer


SendItemInfo_Exit:
  restore
  blr

CreateItemInfo_Exit:

.endm
