#!/bin/bash
echo -n "任意のプロジェクト名を入力:"

# プロジェクト名を変数に追加
read PROJECTNAME

# DBの名前を設定
echo -n "任意のデータベース名を入力:"

read DATABASENAME

# DBのユーザ名を設定
echo -n "データベースのユーザ名を入力:"

read DBUSER

# DBのパスワードを設定
echo -n "データベースのパスワードを入力"

read DBPASSWORD

# 同じ名前のプロジェクトがある場合は削除
rm -rf $PROJECTNAME

# プロジェクトフォルダの追加
mkdir $PROJECTNAME


################ PostgresSQL関連 ###############
# PostgresSQLの初期データディレクトリ
mkdir $PROJECTNAME/db

# PostgreSQLの初期データ投入SQL作成
echo \
"-- テーブル作成
CREATE TABLE users(
  id integer,
  name varchar(50)
);
-- 初期データを挿入
INSERT INTO users VALUES(1,'Tarou');" >> $PROJECTNAME/db/init.sql

############### Java,Gradle関連 ###############

# JavaとGradleの作業ディレクトリを作成
mkdir $PROJECTNAME/back

# プロジェクトディレクトリ作成
mkdir $PROJECTNAME/back/app

# gitkeepを追加
touch $PROJECTNAME/back/app/.gitkeep

# JavaとGradle用のDockerfileを作成
echo \
'FROM openjdk:11
RUN apt-get update
RUN apt-get -y install curl
RUN apt-get -y install zip
RUN curl -s https://get.sdkman.io | bash\n
RUN echo ". $HOME/.sdkman/bin/sdkman-init.sh; sdk install gradle" | bash
WORKDIR /app/' >> $PROJECTNAME/back/Dockerfile

############### Angular,Node.js関連 ###############
# Angular用の作業ディレクトリを作成
mkdir $PROJECTNAME/front

# プロジェクトディレクトリ作成
mkdir $PROJECTNAME/front/app

# gitkeep作成
touch $PROJECTNAME/front/app/.gitkeep

# AngularとNode.js用のDockerfileを作成
echo \
'FROM node:latest
WORKDIR /app
RUN npm install -g npm && \
    npm install -g @angular/cli
EXPOSE 4200' >> $PROJECTNAME/front/Dockerfile

############### docker-compose.yml ###############
echo \
"version: '3.8'
services:
  db:
    image: postgres:12.11
    container_name: db
    restart: always
    environment:
      POSTGRES_USER: $DBUSER
      POSTGRES_PASSWORD: $DBPASSWORD
      POSTGRES_DB: $DATABASENAME
      TZ: "Asia/Tokyo"
    ports:
      - 5432:5432
    volumes:
      - ./db:/docker-entrypoint-initdb.d
  back:
    container_name: back
    build: ./back
    depends_on:
      - db
    ports:
      - 8080:8080
    tty: true
    volumes:
      - ./back/app:/app:cached
    working_dir: /app
  front:
    container_name: front
    build: ./front
    ports:
      - 4200:4200
    volumes:
      - ./front/project:/app:cached
    stdin_open: true
    tty: true
volumes:
  postgres:
    driver: local" >> $PROJECTNAME/docker-compose.yml

############### .devcontainer作成 ###############
mkdir $PROJECTNAME/.devcontainer

echo \
"{
    \"name\": \"back\",
    \"workspaceFolder\": \"/app\",
    \"dockerComposeFile\": \"../docker-compose.yml\",
    \"settings\": {
        \"terminal.integrated.defaultProfile.linux\": \"/bin/bash\",
    },
    \"service\": \"back\", //attachするコンテナはbackを指定
    \"extensions\": [
        \"vscjava.vscode-java-pack\", // JavaExtensionPack
        \"pivotal.vscode-boot-dev-pack\", // Spring Boot Extension Pack
        \"gabrielbb.vscode-lombok\" //Lombok Annotations Support For VS Code
    ]
}" >> $PROJECTNAME/.devcontainer/devcontainer.json

############### Docker コンテナ作成・起動・削除 シェル作成 ###############
# コンテナ作成・起動シェル作成
echo \
'sudo docker-compose build
sudo docker-compose up -d' >> $PROJECTNAME/startDocker.sh

# コンテナ停止シェル作成
echo 'sudo docker-compose down' >> $PROJECTNAME/stopDocker.sh

# コンテナ削除シェル作成
echo \
'sudo docker-compose down
sudo docker system prune -a' >> $PROJECTNAME/deleteDocker.sh

# コンテナに入るシェルの作成
echo \
"echo 'db --> 1 /back --> 2 / front --> 3'
echo -n "開きたいコンテナを選択してください:"
read SELECTCONTAINER
if [ \$SELECTCONTAINER -eq 1 ]; then
    echo [postgres]コンテナを開きます。
    echo PostgresSQLへの接続コマンドは以下のコマンドを実行してください
    echo psql -U $DBUSER -d $DATABASENAME
    sudo docker exec -it db /bin/bash
elif [ \$SELECTCONTAINER -eq 2 ]; then
    echo [back]コンテナを開きます。
    echo JavaとGradleのVersion確認コマンドは以下を実行してください
    echo java --version
    echo gradle -v
    sudo docker exec -it back /bin/bash
elif [ \$SELECTCONTAINER -eq 3 ]; then
    echo [front]コンテナを開きます。
    echo Node.jsのVersion確認コマンドは以下を実行してください。
    echo node -v
    sudo docker exec -it front /bin/bash
else
    echo 範囲外値が入力されました。
    echo 再度シェルを実行してください。
fi" >> $PROJECTNAME/openContainer.sh

# 作成したプロジェクトにフル権限を設定
sudo chmod -R 777 $PROJECTNAME

# コンテナ起動
cd $PROJECTNAME
sudo docker-compose build
sudo docker-compose up -d
