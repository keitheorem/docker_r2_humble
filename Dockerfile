# Start from the ROS 2 Humble desktop full image
FROM osrf/ros:humble-desktop-full

# Configure GUI
ENV QT_X11_NO_MITSHM=1
ENV EDITOR=nano
ENV XDG_RUNTIME_DIR=/tmp

# Install nano, vim, and other dependencies
RUN apt-get update \
  && apt-get install -y \
  nano \
  vim \
  git \
  gedit \
  python3 python3-pip \
  cmake \
  curl \
  gazebo \
  python3-pydantic \
  ros-humble-gazebo-ros \
  libglu1-mesa-dev \
  ros-humble-gazebo-ros-pkgs \
  ros-humble-joint-state-publisher \
  ros-humble-joint-state-publisher-gui \
  ros-humble-robot-localization \
  ros-humble-plotjuggler-ros \
  ros-humble-robot-state-publisher \
  ros-humble-ros2bag \
  ros-humble-rosbag2-storage-default-plugins \
  ros-humble-imu-tools \
  ros-humble-rqt-tf-tree \
  ros-humble-rmw-fastrtps-cpp \
  ros-humble-rmw-cyclonedds-cpp \
  ros-humble-slam-toolbox \
  ros-humble-twist-mux \
  ros-humble-usb-cam \
  ros-humble-xacro \
  ros-humble-navigation2 \
  ros-humble-nav2-bringup \
  ros-humble-moveit \
  ruby-dev \
  rviz \
  tmux \
  wget \
  xorg-dev \
  zsh \
  && rm -rf /var/lib/apt/lists/*

# Set up NVIDIA Container Toolkit
RUN curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add - \
  && distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
  && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list \
  && apt-get update \
  && apt-get install -y nvidia-container-toolkit \
  && rm -rf /var/lib/apt/lists/*

# Copy the requirements file into the container
COPY requirements.txt .

# Install the dependencies from the requirements file
RUN pip install --no-cache-dir -r requirements.txt

# Install PyTorch with CUDA support
RUN pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Set up user
ARG USERNAME=keitheorem
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create a non-root user
RUN groupadd --gid $USER_GID $USERNAME \
  && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
  && mkdir /home/$USERNAME/.config && chown $USER_UID:$USER_GID /home/$USERNAME/.config

# Set up sudo
RUN apt-get update \
  && apt-get install -y sudo \
  && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
  && chmod 0440 /etc/sudoers.d/$USERNAME \
  && rm -rf /var/lib/apt/lists/*

# Create working directory in home
RUN mkdir /home/$USERNAME/ros2_ws

# Copy the entrypoint and bashrc scripts so we have our container's environment set up correctly
COPY entrypoint.sh /entrypoint.sh
COPY bashrc /home/${USERNAME}/.bashrc
COPY Dockerfile /Dockerfile

# Set up entrypoint and default command
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
CMD ["bash"]

# Switch to non-root user
USER keitheorem

# Switch to root user
USER root
