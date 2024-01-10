# Pull upstream CamundaBPM Tomcat image and build the logger jar with dependencies
FROM camunda/camunda-bpm-platform:tomcat-7.20.0 as builder
USER root
RUN mkdir /app
COPY . /app
RUN chown -R camunda:camunda /app \
    && chmod -R 775 /app
USER camunda
WORKDIR /app
# Build the logger project
RUN ./mvnw clean package

FROM camunda/camunda-bpm-platform:tomcat-7.20.0
ENV PRETTY_JSON_LOG=false

# Remove the slf4j-jdj14 bridge and slf4j-api libraries that are packaged with CamundaBPM tomcat distribution
RUN rm -rf /camunda/lib/slf4j-jdk14-1.7.26.jar
RUN rm -rf /camunda/lib/slf4j-api-1.7.26.jar

# Add logback configuration
RUN mkdir /camunda/conf/logback
COPY docker/camunda/conf/logback/logback.xml /camunda/conf/logback/logback.xml

# Overwrite global logging configuration for tomcat
COPY docker/camunda/conf/logging.properties /camunda/conf/logging.properties

# Overwrite setenv.sh with additional CLASSPATH config that exposes the libraries at tomcat startup
COPY docker/camunda/bin/setenv.sh /camunda/bin/setenv.sh

# Copy Jar for logging
COPY --chown=camunda:camunda --from=builder /app/target/camunda-json-logging-tomcat-7.20.0.jar /camunda/lib/

