##setup github locally
```
git config --global user.name "suanming1991"
```
##next, set up email address for github account
```
git config --global user.email "zliu79@wisc.edu"
```
## Create new repo:
go to github.com and create a new repo online with <repoName>
```
cd ~
mkdir <repoName>
git init
//optional
	add README.md file
	touch README.md
	git add README.md
git commit -m "<your message>"
git remote add origin https://github.com/suanming1991/<repoName>.git
git push origin master
```
##remove files

```
git rm file.txt
git commit -m "<your message>"
git push
```
you can use wild cards to remove multiple files

```
git rm *.txt
```
