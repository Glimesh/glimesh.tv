wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb && sudo dpkg -i erlang-solutions_2.0_all.deb &&
sudo apt-get update &&
sudo apt-get install -y esl-erlang &&
sudo apt-get install -y elixir &&
sudo apt-get install -y make &&
sudo apt-get install -y build-essential &&
sudo apt-get install -y nodejs &&
sudo apt-get install -y npm &&
sudo apt-get install -y inotify-tools &&
sudo npm cache clean -f &&
sudo npm install -g n &&
sudo n stable &&
PATH="$PATH"