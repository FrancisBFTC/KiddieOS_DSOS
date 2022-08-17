# Comandos de Branches e Merge

### adicionar e navegar para uma nova branch

git checkout -b nova-branch

### apenas navegar para uma branch (para o main)

git checkout main

### criar um arquivo untracked no main

echo > algumarquivo.txt

### navegar para a nova branch criada

git checkout nova-branch

### visualizar as branchs criadas e onde o HEAD aponta

git branch

### a sujeira de arquivos untrackeds veio junto
### então salvar este untracked temporariamente

git stash save "Untrackeds da branch MAIN"

### visualizar a caixinha com os arquivos untrackeds

git stash list

### verificar se há untrackeds, na verdade não há

git status

### Criar um novo arquivo na nova branch

echo > novoarquivo.txt

### adicionar este novo untracked no índice 1 do stash

git stash save "Novo untracked da nova-branch"

### com git status mostra novamente que não há untrackeds

### voltar para a branch MAIN

git checkout main

### Recuperar o arquivo untracked da branch main

git stash pop 0

### Mover o untracked atual para a área staged

git add arquivoarquivo.txt

### Commitar o arquivo staged

git commit -m "Adicionando ao github o arquivo do main"

### Empurrar com push para o github o arquivo commitado

git push origin main

### usando git status verá que está up-to-date (atualizado)

### navegar até a nova-branch

git checkout nova-branch

### Recuperar o 2ª untracked para nova-branch

git stash pop 1

### Mover o untracked atual para staged

git add novoarquivo.txt

### commitar o novo arquivo

git commit -m "Adicionando ao github o arquivo da nova branch"

### Empurrar ao github o novo arquivo commitado para nova branch

git push origin nova-branch

### Verificar todos os commits até então

git log

### Renomear a nova-branch para nova-func

git branch -m nova-func

### navegar para a branch main

git checkout main

### verificar as branchs existentes

git branch

### Mesclar a branch nova-func com a branch main

git merge nova-func

### subir ao github as novas alterações

git push origin main

### renomear novamente a nova-func para o nome original
### a partir da branch main

git branch -m nova-func nova-branch

### Deletar a nova-branch

git branch -d nova-branch

### Subir as alterações pro github

git push origin main

### Visualizar as branchs atuais

git branch


