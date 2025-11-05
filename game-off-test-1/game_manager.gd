extends Node

var mScore = 0
@onready var mScoreLabel = $ScoreLabel

func addCoin():
	mScore+=1
	mScoreLabel.text = "You collected " + str(mScore) + " coins."
