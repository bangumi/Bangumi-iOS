.PHONY: update_preview_date

UID ?= 873244
PREVIEW_PATH ?= Chobits/Preview Content

update_preview_data:
	curl -sSfLo openapi.yaml https://next.bgm.tv/p1/openapi.yaml

	# subject
	curl -sSfLo "$(PREVIEW_PATH)/subject_anime.json" https://next.bgm.tv/p1/subjects/12
	curl -sSfLo "$(PREVIEW_PATH)/subject_anime_episodes.json" https://next.bgm.tv/p1/subjects/12/episodes
	curl -sSfLo "$(PREVIEW_PATH)/subject_book.json" https://next.bgm.tv/p1/subjects/497
	curl -sSfLo "$(PREVIEW_PATH)/subject_music.json" https://next.bgm.tv/p1/subjects/4991
	curl -sSfLo "$(PREVIEW_PATH)/subject_music_episodes.json" https://next.bgm.tv/p1/subjects/4991/episodes
	curl -sSfLo "$(PREVIEW_PATH)/subject_topics.json" https://next.bgm.tv/p1/subjects/12/topics
	curl -sSfLo "$(PREVIEW_PATH)/subject_comments.json" https://next.bgm.tv/p1/subjects/12/comments
	curl -sSfLo "$(PREVIEW_PATH)/user_subject_collections.json" https://next.bgm.tv/p1/users/$(UID)/collections/subjects
	curl -sSfLo "$(PREVIEW_PATH)/user_subject_collection_anime.json" https://next.bgm.tv/p1/users/$(UID)/collections/subjects/12
	curl -sSfLo "$(PREVIEW_PATH)/user_subject_collection_book.json" https://next.bgm.tv/p1/users/$(UID)/collections/subjects/497
	# curl -sSfLo "$(PREVIEW_PATH)/episode_collections.json" https://next.bgm.tv/p1/users/-/collections/subjects/12/episodes

	# character
	curl -sSfLo "$(PREVIEW_PATH)/character.json" https://next.bgm.tv/p1/characters/32

	# person
	curl -sSfLo "$(PREVIEW_PATH)/person.json" https://next.bgm.tv/p1/persons/3862
