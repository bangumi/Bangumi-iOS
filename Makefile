.PHONY: update_preview_date

update_preview_data:
	curl https://next.bgm.tv/p1/openapi.yaml > openapi.yaml
	curl https://next.bgm.tv/p1/subjects/12 > "Chobits/Preview Content/subject_anime.json"
	curl https://next.bgm.tv/p1/subjects/497 > "Chobits/Preview Content/subject_book.json"
	curl https://next.bgm.tv/p1/users/873244/collections/subjects/12 > "Chobits/Preview Content/user_subject_collection_anime.json"
	curl https://next.bgm.tv/p1/users/873244/collections/subjects/497 > "Chobits/Preview Content/user_subject_collection_book.json"

