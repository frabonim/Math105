pandoc -s -t html5 --metadata=lang=en --extract-media=media  --resource-path=../figs "$1" | pbcopy
echo "if no errors then html copied to clipboard"

