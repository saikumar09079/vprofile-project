FROM tomcat:10.1-jdk21-temurin

WORKDIR /usr/local/tomcat

RUN rm -rf webapps/*

COPY target/vprofile-v2.war webapps/ROOT.war

EXPOSE 8081

CMD ["catalina.sh", "run"]
