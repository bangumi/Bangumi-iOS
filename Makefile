.PHONY: update_preview_date

UID ?= 873244
PREVIEW_PATH ?= Chobits/Preview Content


update_api:
	curl -sSfLo openapi.yaml https://next.bgm.tv/p1/openapi.yaml

update_subject:
	curl -sSfLo "$(PREVIEW_PATH)/subject_anime.json" https://next.bgm.tv/p1/subjects/12
	curl -sSfLo "$(PREVIEW_PATH)/subject_book.json" https://next.bgm.tv/p1/subjects/497
	curl -sSfLo "$(PREVIEW_PATH)/subject_music.json" https://next.bgm.tv/p1/subjects/4991
	curl -sSfLo "$(PREVIEW_PATH)/subject_music_episodes.json" https://next.bgm.tv/p1/subjects/4991/episodes
	curl -sSfLo "$(PREVIEW_PATH)/subject_offprints.json" https://next.bgm.tv/p1/subjects/497/relations?offprint=true
	curl -sSfLo "$(PREVIEW_PATH)/subject_relations.json" https://next.bgm.tv/p1/subjects/12/relations
	curl -sSfLo "$(PREVIEW_PATH)/subject_characters.json" https://next.bgm.tv/p1/subjects/12/characters
	curl -sSfLo "$(PREVIEW_PATH)/subject_staffs.json" https://next.bgm.tv/p1/subjects/12/staffs
	curl -sSfLo "$(PREVIEW_PATH)/subject_recs.json" https://next.bgm.tv/p1/subjects/12/recs
	curl -sSfLo "$(PREVIEW_PATH)/subject_reviews.json" https://next.bgm.tv/p1/subjects/12/reviews
	curl -sSfLo "$(PREVIEW_PATH)/subject_topics.json" https://next.bgm.tv/p1/subjects/12/topics
	curl -sSfLo "$(PREVIEW_PATH)/subject_comments.json" https://next.bgm.tv/p1/subjects/12/comments

update_episode:
	curl -sSfLo "$(PREVIEW_PATH)/subject_anime_episodes.json" https://next.bgm.tv/p1/subjects/12/episodes
	curl -sSfLo "$(PREVIEW_PATH)/episode_comments.json" https://next.bgm.tv/p1/subjects/-/episodes/1027/comments

update_character:
	curl -sSfLo "$(PREVIEW_PATH)/character.json" https://next.bgm.tv/p1/characters/32
	curl -sSfLo "$(PREVIEW_PATH)/character_casts.json" https://next.bgm.tv/p1/characters/32/casts
	curl -sSfLo "$(PREVIEW_PATH)/character_collects.json" https://next.bgm.tv/p1/characters/32/collects
	curl -sSfLo "$(PREVIEW_PATH)/user_character_collection.json" https://next.bgm.tv/p1/users/$(UID)/collections/characters/32
	curl -sSfLo "$(PREVIEW_PATH)/user_character_collections.json" https://next.bgm.tv/p1/users/$(UID)/collections/characters

update_person:
	curl -sSfLo "$(PREVIEW_PATH)/person.json" https://next.bgm.tv/p1/persons/3862
	curl -sSfLo "$(PREVIEW_PATH)/person_works.json" https://next.bgm.tv/p1/persons/3862/works
	curl -sSfLo "$(PREVIEW_PATH)/person_casts.json" https://next.bgm.tv/p1/persons/3862/casts
	curl -sSfLo "$(PREVIEW_PATH)/person_collects.json" https://next.bgm.tv/p1/persons/3862/collects
	curl -sSfLo "$(PREVIEW_PATH)/user_person_collection.json" https://next.bgm.tv/p1/users/$(UID)/collections/persons/3862
	curl -sSfLo "$(PREVIEW_PATH)/user_person_collections.json" https://next.bgm.tv/p1/users/$(UID)/collections/persons

update_user:
	curl -sSfLo "$(PREVIEW_PATH)/user.json" https://next.bgm.tv/p1/users/$(UID)
	curl -sSfLo "$(PREVIEW_PATH)/user_timeline.json" https://next.bgm.tv/p1/users/$(UID)/timeline
	curl -sSfLo "$(PREVIEW_PATH)/user_groups.json" https://next.bgm.tv/p1/users/$(UID)/groups
	curl -sSfLo "$(PREVIEW_PATH)/user_blogs.json" https://next.bgm.tv/p1/users/$(UID)/blogs
	curl -sSfLo "$(PREVIEW_PATH)/user_indexes.json" https://next.bgm.tv/p1/users/$(UID)/indexes
	curl -sSfLo "$(PREVIEW_PATH)/user_friends.json" https://next.bgm.tv/p1/users/$(UID)/friends
	curl -sSfLo "$(PREVIEW_PATH)/user_followers.json" https://next.bgm.tv/p1/users/$(UID)/followers
	curl -sSfLo "$(PREVIEW_PATH)/user_subject_collections.json" https://next.bgm.tv/p1/users/$(UID)/collections/subjects
	curl -sSfLo "$(PREVIEW_PATH)/user_person_collections.json" https://next.bgm.tv/p1/users/$(UID)/collections/persons
	curl -sSfLo "$(PREVIEW_PATH)/user_character_collections.json" https://next.bgm.tv/p1/users/$(UID)/collections/characters
	curl -sSfLo "$(PREVIEW_PATH)/user_index_collections.json" https://next.bgm.tv/p1/users/$(UID)/collections/indexes
	curl -sSfLo "$(PREVIEW_PATH)/user_subject_collection_anime.json" https://next.bgm.tv/p1/users/$(UID)/collections/subjects/12
	curl -sSfLo "$(PREVIEW_PATH)/user_subject_collection_book.json" https://next.bgm.tv/p1/users/$(UID)/collections/subjects/497

	# curl -sSfLo "$(PREVIEW_PATH)/episode_collections.json" https://next.bgm.tv/p1/users/-/collections/subjects/12/episodes

update_timeline:
	curl -sSfLo "$(PREVIEW_PATH)/timeline.json" https://next.bgm.tv/p1/timeline

update_blog:
	curl -sSfLo "$(PREVIEW_PATH)/blog.json" https://next.bgm.tv/p1/blogs/347290
	curl -sSfLo "$(PREVIEW_PATH)/blog_subjects.json" https://next.bgm.tv/p1/blogs/347290/subjects

update_trending:
	curl -sSfLo "$(PREVIEW_PATH)/trending_subjects_anime.json" https://next.bgm.tv/p1/trending/subjects?type=2

update_index:
	curl -sSfLo "$(PREVIEW_PATH)/index.json" https://next.bgm.tv/p1/indexes/83001
	curl -sSfLo "$(PREVIEW_PATH)/index_related.json" https://next.bgm.tv/p1/indexes/83001/related
