yt-rss(){
	if [ -z "$1" ]; then
		echo "Usage: yt-rss <yt_url>"
		return 1
	fi
        local id=$(curl -sL "$1" | grep -o 'channel_id=UC[^"]*' | head -n1 | cut -d= -f2)
	if [ -z "$id" ]; then
		echo "Could not extract channel ID from the provided URL."
		return 1
	else
		echo "https://www.youtube.com/feeds/videos.xml?channel_id=$id"
	fi
}
