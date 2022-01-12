FROM centos:7
WORKDIR /tmp
ENV PYTHONVERSION=3.9.9
ENV PYTHON_ARCHIVE_MD5HASH=a2da2a456c078db131734ff62de10ed5
RUN yum update -y 
RUN yum install -y epel-release
RUN yum groupinstall -y "Development Tools"
RUN yum install -y bzip2-devel libffi-devel openssl-devel readline-devel tk-devel wget xz-devel zlib-devel
RUN gcc --version
RUN wget https://www.sqlite.org/2022/sqlite-autoconf-3370200.tar.gz
RUN tar xvf sqlite-autoconf-3370200.tar.gz
RUN cd sqlite* && ./configure && make install 
RUN echo "export LD_LIBRARY_PATH=/usr/local/lib:\$LD_LIBRARY_PATH" > /etc/profile.d/python3.sh
RUN wget https://www.python.org/ftp/python/${PYTHONVERSION}/Python-${PYTHONVERSION}.tgz
RUN echo "${PYTHON_ARCHIVE_MD5HASH} Python-${PYTHONVERSION}.tgz" | md5sum -c
RUN tar xvf Python-${PYTHONVERSION}.tgz
RUN cd Python-${PYTHONVERSION} && ./configure --enable-shared --enable-optimizations --with-ensurepip=install && make altinstall && make bininstall
RUN source /etc/profile.d/python3.sh && /usr/local/bin/python3 -m pip install --no-cache-dir --upgrade pip setuptools
RUN yum install -y centos-release-scl epel-release
RUN yum install -y httpd24-httpd httpd24-httpd-devel
RUN git clone https://github.com/GrahamDumpleton/mod_wsgi.git
RUN source /etc/profile.d/python3.sh && source /opt/rh/httpd24/enable && cd mod_wsgi && git checkout tags/4.9.0 && ./configure --with-python=/usr/local/bin/python3 && make && make install
COPY ./wsgi.conf /opt/rh/httpd24/root/etc/httpd/conf.d/wsgi.conf
RUN mkdir /src
WORKDIR /src
RUN source /etc/profile.d/python3.sh && /usr/local/bin/python3 -m venv venv
RUN source /etc/profile.d/python3.sh && /src/venv/bin/pip install --no-cache-dir django==2.2.24
RUN source /etc/profile.d/python3.sh && /src/venv/bin/django-admin startproject mysite
COPY ./settings.py /src/mysite/mysite/settings.py
RUN source /etc/profile.d/python3.sh && /src/venv/bin/python mysite/manage.py collectstatic

EXPOSE 80

CMD ["/bin/bash", "-c", "source /etc/profile.d/python3.sh && source /opt/rh/httpd24/enable && httpd -D FOREGROUND"]
