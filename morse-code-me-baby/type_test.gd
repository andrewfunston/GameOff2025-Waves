extends Node2D

@onready var mRichTextLabel = $RichTextLabel

var mIsPressed:bool
var mPressedTime:float
var mFreeTime:float

const sShortPressMax:float = .25
const sSpaceBetweenLetters:float = sShortPressMax + .5
const sSpaceBetweenWords:float = sSpaceBetweenLetters + 1

enum MorsePress { short, long }
var mMorseToProcess:Array=[]
var mCurrentLetters:Array=[]

var sMorseMap:Dictionary[Array, String] = {
	[MorsePress.short, MorsePress.long]: "A",
	[MorsePress.long, MorsePress.short, MorsePress.short, MorsePress.short]:"B",
	[MorsePress.long, MorsePress.short, MorsePress.long, MorsePress.short]:"C",
	[MorsePress.long, MorsePress.short, MorsePress.short]:"D",
	[MorsePress.short]:"E",
	[MorsePress.short, MorsePress.short, MorsePress.long, MorsePress.short]:"F",
	[MorsePress.long, MorsePress.long, MorsePress.short]:"G",
	[MorsePress.short, MorsePress.short, MorsePress.short, MorsePress.short]:"H",
	[MorsePress.short, MorsePress.short]:"I",
	[MorsePress.short, MorsePress.long, MorsePress.long, MorsePress.long]:"J",
	[MorsePress.long, MorsePress.short, MorsePress.long]:"K",
	[MorsePress.short, MorsePress.long, MorsePress.short, MorsePress.short]:"L",
	[MorsePress.long, MorsePress.long]:"M",
	[MorsePress.long, MorsePress.short]:"N",
	[MorsePress.long, MorsePress.long, MorsePress.long]:"O",
	[MorsePress.short, MorsePress.long, MorsePress.long, MorsePress.short]:"P",
	[MorsePress.long, MorsePress.long, MorsePress.short, MorsePress.long]:"Q",
	[MorsePress.short, MorsePress.long, MorsePress.short]:"R",
	[MorsePress.short, MorsePress.short, MorsePress.short]:"S",
	[MorsePress.long]:"T",
	[MorsePress.short, MorsePress.short, MorsePress.long]:"U",
	[MorsePress.short, MorsePress.short, MorsePress.short, MorsePress.long]:"V",
	[MorsePress.short, MorsePress.long, MorsePress.long]:"W",
	[MorsePress.long, MorsePress.short, MorsePress.short, MorsePress.long]:"X",
	[MorsePress.long, MorsePress.short, MorsePress.long, MorsePress.long]:"Y",
	[MorsePress.long, MorsePress.long, MorsePress.short, MorsePress.short]:"Z"
}

func _process(delta):
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()

	if Input.is_action_just_pressed("morse"):
		mIsPressed = true
		mFreeTime = 0
		mPressedTime = 0
	elif Input.is_action_pressed("morse"):
		mPressedTime+=delta
	elif Input.is_action_just_released("morse"):
		mIsPressed = false
		processRelease()
	elif not mIsPressed :
		mFreeTime+=delta
		if not mCurrentLetters.is_empty() and mMorseToProcess.is_empty() and mFreeTime >= sSpaceBetweenWords:
			print(mFreeTime)
			lettersToWords()
		elif not mMorseToProcess.is_empty() and mFreeTime >= sSpaceBetweenLetters:
			print(mFreeTime)
			boopsToLetters()

func processRelease():
	# This is a short press
	if mPressedTime <= sShortPressMax:
		print("add short")
		mMorseToProcess.append(MorsePress.short)
	# This is a long press
	elif mPressedTime > sShortPressMax:
		print("add long")
		mMorseToProcess.append(MorsePress.long)

func boopsToLetters():
	print("boopsToLetters " + str(mMorseToProcess))
	
	# mMorseToProcess is a list of long/shorts - we need to turn them into letters
	# sMorseMap is a map of long/short arrays TO letter
	for currentBoops in sMorseMap:
		var letter = sMorseMap[currentBoops]
		if currentBoops.size() != mMorseToProcess.size():
			continue
			
		var index:int = 0
		for boop in currentBoops:
			if boop == mMorseToProcess[index]:
				index+=1
			else:
				break
			
			if(index == mMorseToProcess.size()):
				print("added:" + letter)
				mCurrentLetters.append(letter)
				mMorseToProcess.clear()
				return

	print("added nothing you dumb bitch")
	mMorseToProcess.clear()

func lettersToWords():
	print("lettersToWords " + str(mCurrentLetters))
	
	mRichTextLabel.clear()
	mRichTextLabel.add_text("".join(mCurrentLetters))
	
	mCurrentLetters.clear()
