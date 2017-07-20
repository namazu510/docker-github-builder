# docker-github-builder

githubのレポジトリからソースを落として
そのまま`docker build`して
docker registryに`docker push `する子.


# 実行
```sh
bundle install --path ./vendor/bundler
bundle exec main.rb
```
# 叩く
* wsで8888に接続.
* メッセージ送る(どんなの送るかはmain.rbみて察する)
* ログがどんどん飛んでくるから読みつつ終わるのを待つ
