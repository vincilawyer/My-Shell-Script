#############################################################################################################################################################################################
##############################################################################   9.Docker  ################################################################################################
############################################################################################################################################################################################
###   说明：查看容器docker ps -a；下载镜像 docker pull ；删除镜像 docker rmi ； 运行容器 docker run ；停止容器 docker stop container_id ；删除 docker rm container_id ；恢复容器 docker start container_id
Version=1.00  #版本号  

### 菜单栏
docker_menu=(
    "安装Docker"           "install_Docker"
    "Chatgpt应用"          'page true "Chatgpt-Docker" "${gpt_menu[@]}"'
    "查看Docker容器"        'echo "Docker容器状况：" && docker ps -a && echo; echo "提示：可使用docker stop 或 docker rm 语句加容器 ID 或者名称来停止容器的运行或者删除容器 "'
    "删除所有容器"          'confirm "是否删除所有Docker容器？" "已取消删除容器" || ( docker stop $(docker ps -a -q) &&  docker rm $(docker ps -a -q) && echo "已删除所有容器" )'
    "程序管理器"            'get_appmanage_menu "docker"; page true "Docker" "${appmanage_menu[@]}"'
    )
    
###初始化
function docker_initial {
    #加载chatgpt模块
    path_chatgpt="$data_path/chatgpt_docker.src.sh"
    link_chatgpt="${link_repositories}vinci/application/docker/chatgpt_docker.src.sh"
    update_load "$path_chatgpt" "$link_chatgpt" "chatgpt" 1 "$startcode" 

}
    
#######  安装Docker及依赖包  #######
function install_Docker {
     installed "docker" && return
    
    # 安装docker，具体在https://docs.docker.com/engine/install/debian/中查看说明教程
    # 卸载冲突包
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
    
    # 更新apt包索引并安装包以允许apt通过 HTTPS 使用存储库：
    sudo apt-get update
    sudo apt-get install ca-certificates curl gnupg

    #添加Docker官方GPG密钥：
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    
    #使用以下命令设置存储库：
    echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    #更新apt包索引：
    sudo apt-get update
    #安装最新版本 Docker 引擎、containerd 和 Docker Compose。
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}
