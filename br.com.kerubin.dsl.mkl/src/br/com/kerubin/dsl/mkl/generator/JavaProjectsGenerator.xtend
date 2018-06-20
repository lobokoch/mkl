package br.com.kerubin.dsl.mkl.generator

import static extension br.com.kerubin.dsl.mkl.generator.Utils.*

class JavaProjectsGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateJavaProjects()
	}
	
	def generateJavaProjects() {
		val PROJECT_CLIENT = projectClientName
		val PROJECT_SERVER = projectServerName
		
		val MODULES_DIR = getModulesDir
		
		//Parent first
		generateFile(MODULES_DIR + 'pom.xml', generateParentPOM)
		
		generateFile(MODULES_DIR + PROJECT_CLIENT + '/pom.xml', generateClientPOM(PROJECT_CLIENT))
		generateFile(MODULES_DIR + PROJECT_SERVER + '/pom.xml', generateServerPOM(PROJECT_SERVER, PROJECT_CLIENT))
		
		generateApplicationProject
	}
	
	def private getApplicationName() {
		service.domain + '-' + service.name + '-' + projectApplicationName
	}
	
	def private generateApplicationProject() {
		val MODULES_DIR = getModulesDir
		val PROJECT_APPLICATION = projectApplicationName
		val PROJECT_SERVER = projectServerName
		val mainClassName = service.domain.toFirstUpper + service.name.toFirstUpper + 'Application'
		
		generateFile(MODULES_DIR + PROJECT_APPLICATION + '/pom.xml', generateApplicationPOM(applicationName, PROJECT_SERVER))
		
		val appSourceFolder = applicationSourceFolder
		val path = service.servicePackagePath
		generateFile(appSourceFolder + path + '/' + mainClassName + '.java', generateApplicationMain(mainClassName))
		generateFile(getApplicationResourcesFolder + 'bootstrap.yml', generateApplicationBootstrap())
	}
	
	def generateApplicationBootstrap() {
		'''
		spring:
		  application:
		    name: «applicationName»
		  cloud:
		    config:
		      uri: «service.configuration.cloudConfigUri»
		'''
	}
	
	
	def private generateApplicationMain(String mainClassName) {
		'''
		package «service.servicePackage»;
		
		import org.springframework.boot.SpringApplication;
		import org.springframework.boot.autoconfigure.SpringBootApplication;
		import org.springframework.boot.autoconfigure.domain.EntityScan;
		import org.springframework.cloud.netflix.eureka.EnableEurekaClient;
		import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
		
		@SpringBootApplication
		@EnableEurekaClient
		@EnableJpaRepositories("«basePackage»")
		@EntityScan("«basePackage»")
		public class «mainClassName» {
		
			public static void main(String[] args) {
				SpringApplication.run(«mainClassName».class, args);
			}
		}
		'''
	}
	
	
	def generateApplicationPOM(String applicationProjectName, String serverProjectName) {
		'''
		<?xml version="1.0" encoding="UTF-8"?>
		<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
			xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
			<modelVersion>4.0.0</modelVersion>
		
			<artifactId>«applicationProjectName»</artifactId>
			<packaging>jar</packaging>
		
			<name>«applicationProjectName»</name>
			<description>Kerubin «applicationProjectName» Service</description>
		
			«getPOMParentSectionFull»
		
			<dependencies>
				<dependency>
					<groupId>${project.groupId}</groupId>
					<artifactId>«service.domain»-«service.name»-«serverProjectName»</artifactId>
					<version>${project.version}</version>
				</dependency>
				<dependency>
					<groupId>org.springframework.boot</groupId>
					<artifactId>spring-boot-starter-actuator</artifactId>
				</dependency>
				<dependency>
					<groupId>org.springframework.boot</groupId>
					<artifactId>spring-boot-starter-data-jpa</artifactId>
				</dependency>
				<dependency>
					<groupId>org.springframework.boot</groupId>
					<artifactId>spring-boot-starter-web</artifactId>
				</dependency>
				<dependency>
					<groupId>org.springframework.cloud</groupId>
					<artifactId>spring-cloud-starter-config</artifactId>
				</dependency>
				<dependency>
					<groupId>org.springframework.cloud</groupId>
					<artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
				</dependency>
				<dependency>
					<groupId>org.postgresql</groupId>
					<artifactId>postgresql</artifactId>
					<scope>runtime</scope>
				</dependency>
				<dependency>
					<groupId>org.flywaydb</groupId>
					<artifactId>flyway-core</artifactId>
				</dependency>
				<dependency>
					<groupId>org.springframework.boot</groupId>
					<artifactId>spring-boot-starter-test</artifactId>
					<scope>test</scope>
				</dependency>
			</dependencies>
			
			<!--
			<dependencyManagement>
				<dependencies>
					<dependency>
						<groupId>org.springframework.cloud</groupId>
						<artifactId>spring-cloud-dependencies</artifactId>
						<version>${spring-cloud.version}</version>
						<type>pom</type>
						<scope>import</scope>
					</dependency>
				</dependencies>
			</dependencyManagement>
		
			<build>
				<plugins>
					<plugin>
						<groupId>org.springframework.boot</groupId>
						<artifactId>spring-boot-maven-plugin</artifactId>
					</plugin>
				</plugins>
			</build>
		
			<repositories>
				<repository>
					<id>spring-milestones</id>
					<name>Spring Milestones</name>
					<url>https://repo.spring.io/milestone</url>
					<snapshots>
						<enabled>false</enabled>
					</snapshots>
				</repository>
			</repositories>
			-->
		
		
		</project>
		'''
	}
	
	def generateServerPOM(String serverProjectName, String clientProjectName) {
		'''
		<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
		    xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
		    <modelVersion>4.0.0</modelVersion>
		    <artifactId>«service.domain»-«service.name»-«serverProjectName»</artifactId>
		    <packaging>jar</packaging>
		    «getPOMParentSectionFull»
		    <dependencies>
		        <dependency>
		            <groupId>${project.groupId}</groupId>
		            <artifactId>«service.domain»-«service.name»-«clientProjectName»</artifactId>
		            <version>${project.version}</version>
		        </dependency>
		        <dependency>
		            <groupId>org.springframework.boot</groupId>
		            <artifactId>spring-boot-starter-data-jpa</artifactId>
		        </dependency>
		        <dependency>
		            <groupId>org.springframework.boot</groupId>
		            <artifactId>spring-boot-starter-web</artifactId>
		        </dependency>
		        <dependency>
		            <groupId>org.postgresql</groupId>
		            <artifactId>postgresql</artifactId>
		            <scope>runtime</scope>
		        </dependency>
		        <dependency>
		          <groupId>org.modelmapper</groupId>
		          <artifactId>modelmapper</artifactId>
		          <version>1.1.0</version>
		        </dependency>
		        
		    </dependencies>
		    <build>
		        <plugins>
		        	«getSourceFolderPlugin»
		        </plugins>
		      </build>
		</project>
		'''
	}
	
	def static getSourceFolderPlugin() {
		'''
          <plugin>
            <groupId>org.codehaus.mojo</groupId>
            <artifactId>build-helper-maven-plugin</artifactId>
            <version>3.0.0</version>
            <executions>
              <execution>
                <id>add-source</id>
                <phase>generate-sources</phase>
                <goals>
                  <goal>add-source</goal>
                </goals>
                <configuration>
                  <sources>
                    <source>«getJavaSourceGen»</source>
                  </sources>
                </configuration>
              </execution>
            </executions>
          </plugin>
		'''
	}
	
	def getPOMParentSection() {
		'''
		        <groupId>«configuration.groupId»</groupId>
		        <artifactId>«service.domain»-«service.name»-parent</artifactId>
		        <version>«configuration.version»</version>
		'''
	}
	
	def getPOMParentSectionFull() {
		'''
		    <parent>
		        «getPOMParentSection»
		    </parent>
		'''
	}
	
	
	def generateClientPOM(String projectName) {
		'''
		<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
		    xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">    
		    <modelVersion>4.0.0</modelVersion>
		    <artifactId>«service.domain»-«service.name»-«projectName»</artifactId>
		    <packaging>jar</packaging>
		    «getPOMParentSectionFull»
		    <dependencies>
		    	<dependency>
		    		<groupId>org.springframework.boot</groupId>
		    		<artifactId>spring-boot-starter-data-jpa</artifactId>
		    	</dependency>
		    	<dependency>
		    		<groupId>org.springframework.boot</groupId>
		    		<artifactId>spring-boot-starter-web</artifactId>
		    	</dependency>
		    </dependencies>
		    <build>
		        <defaultGoal>install</defaultGoal>
		        <plugins>
		        	«getSourceFolderPlugin»
		        	<plugin>
		        		<groupId>org.codehaus.mojo</groupId>
		        		<artifactId>templating-maven-plugin</artifactId>
		        		<version>1.0.0</version>
		        		<executions>
		        			<execution>
		        				<id>generate-version-class</id>
		        				<goals>
		        					<goal>filter-sources</goal>
		        				</goals>
		        			</execution>
		        		</executions>
		        	</plugin>
		        </plugins>
		    </build>
		</project>
		
		
		'''
	}
	
	def generateJavaProject(String projectName) {
		'''
		<?xml version="1.0" encoding="UTF-8"?>
		<projectDescription>
			<name>«service.domain»-«service.name»-«projectName»</name>
			<comment></comment>
			<projects>
			</projects>
			<buildSpec>
				<buildCommand>
					<name>org.eclipse.jdt.core.javabuilder</name>
					<arguments>
					</arguments>
				</buildCommand>
				<buildCommand>
					<name>org.eclipse.m2e.core.maven2Builder</name>
					<arguments>
					</arguments>
				</buildCommand>
			</buildSpec>
			<natures>
				<nature>org.eclipse.jdt.core.javanature</nature>
				<nature>org.eclipse.m2e.core.maven2Nature</nature>
			</natures>
		</projectDescription>
		'''
	}
	
	//Based on: https://docs.spring.io/spring-boot/docs/current/reference/html/using-boot-build-systems.html#using-boot-maven-without-a-parent
	//and: https://www.surasint.com/spring-boot-with-no-parent-example/
	def generateParentPOM() {
		'''
		<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
			xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
			<modelVersion>4.0.0</modelVersion>
			«getPOMParentSection»
			<packaging>pom</packaging>
			<name>«service.domain»-«service.name»-parent</name>
			<description>«service.name»</description>
			<organization>
				<name>Kerubin</name>
				<url>http://www.kerubin.com.br</url>
			</organization>
			<developers>
				<developer>
					<name>Kerubin</name>
				</developer>
			</developers>
			<properties>
				<project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
				<maven.compiler.source>1.8</maven.compiler.source>
				<maven.compiler.target>1.8</maven.compiler.target>		
				<project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
				<project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
				<java.version>1.8</java.version>
				<springframework.boot.version>2.0.1.RELEASE</springframework.boot.version>
				<spring-cloud.version>Finchley.RC1</spring-cloud.version>			
				<spring-data-releasetrain.version>Kay-SR6</spring-data-releasetrain.version>			
			</properties>
			<modules>
				<module>«projectClientName»</module>
				<module>«projectServerName»</module>
				<module>«projectApplicationName»</module>
			</modules>
			<dependencyManagement>
				<dependencies>
					<!-- Override Spring Data release train provided by Spring Boot -->
					<dependency>
						<groupId>org.springframework.data</groupId>
						<artifactId>spring-data-releasetrain</artifactId>
						<version>${spring-data-releasetrain.version}</version>
						<type>pom</type>
						<scope>import</scope>
					</dependency>
					<dependency>
						<groupId>org.springframework.boot</groupId>
						<artifactId>spring-boot-dependencies</artifactId>
						<version>${springframework.boot.version}</version>
						<type>pom</type>
						<scope>import</scope>
					</dependency>
					<dependency>
						<groupId>org.springframework.cloud</groupId>
						<artifactId>spring-cloud-dependencies</artifactId>
						<version>${spring-cloud.version}</version>
						<type>pom</type>
						<scope>import</scope>
					</dependency>
				</dependencies>
			</dependencyManagement>
			<build>
				<plugins>
					<plugin>
						<groupId>org.springframework.boot</groupId>
						<artifactId>spring-boot-maven-plugin</artifactId>
					</plugin>
				</plugins>
			</build>
			<repositories>
				<repository>
					<id>spring-milestones</id>
					<name>Spring Milestones</name>
					<url>https://repo.spring.io/milestone</url>
					<snapshots>
						<enabled>false</enabled>
					</snapshots>
				</repository>
				<repository>
					<id>spring-libs-release</id>
					<name>Spring Releases</name>
					<url>https://repo.spring.io/libs-release</url>
					<snapshots>
						<enabled>false</enabled>
					</snapshots>
				</repository>
			</repositories>
			
		</project>
		'''
	}
	
	
}