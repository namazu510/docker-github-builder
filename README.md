# docker-github-builder

githubのレポジトリからソースを落として
そのまま`docker build`して
docker registryに`docker push `する子.


# 実行
```sh
bundle install --path ./vendor/bundler
bundle exec main.rb
```
