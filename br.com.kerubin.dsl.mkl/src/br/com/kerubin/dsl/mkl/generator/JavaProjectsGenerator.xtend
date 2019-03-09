package br.com.kerubin.dsl.mkl.generator

import static extension br.com.kerubin.dsl.mkl.generator.Utils.*
import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import br.com.kerubin.dsl.mkl.model.MavenDependency

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
	
	def private getArtifactId(String sufix) {
		var id = service.domain.toLowerCase.replace("_", "") + "-" + service.name.toLowerCase.replace("_", "")
		if (sufix !== null && !sufix.isEmpty) {
			id += "-" + sufix.toLowerCase
		}
		id
	}
	
	def private getApplicationId() {
		val result = mountName(newArrayList(service.domain, service.name, projectApplicationName))
		result
	}
	
	def private generateApplicationProject() {
		val pomFileName = 'pom.xml'
		
		if (fsa.isFile(pomFileName, MklOutputConfigurationProvider.OUTPUT_KEEPED)) {
			//return //Already exists and must not be generated again
		}
		
		val PROJECT_SERVER = projectServerName
		val mainClassName = /*service.domain.textUnderToTextCamel + */service.name.textUnderToTextCamel + 'Application'
		
		generateFileForApp(pomFileName, generateApplicationPOM(PROJECT_SERVER))
		
		val appSourceFolder = applicationSourceFolder
		val path = service.servicePackagePath
		generateFileForApp(appSourceFolder + path + '/' + mainClassName + '.java', generateApplicationMain(mainClassName))
		generateFileForApp(getApplicationResourcesFolder + 'bootstrap.yml', generateResourceSpringBootApplicationBootstrap())
		generateFileForApp(getApplicationResourcesFolder + 'application.yml', generateResourceSpringBootApplication())
	}
	
	def generateResourceSpringBootApplicationBootstrap() {
		'''
		spring:
		  application:
		    name: «applicationId»
		  cloud:
		    config:
		      uri: «service.configuration.cloudConfigUri»
		'''
	}
	
	def generateResourceSpringBootApplication() {
		'''
		server:
		  port: «configuration.servicePort»
		
		spring:
		    datasource:
		        driver-class-name: org.postgresql.Driver
		        username: postgres
		        password: 'postgres'
		        platform: PostgreSQL
		        url: jdbc:postgresql://localhost:5432/«service.domain.toLowerCase»_«service.name.toLowerCase»
		    jpa:
		        database-platform: org.hibernate.dialect.PostgreSQLDialect
		        generate-ddl: false
		        hibernate:
		            ddl-auto: none
		        show-sql: true
		    rabbitmq:
		        port: 5672
		        username: admin
		        password: admin
		        host: localhost
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
	
	def generateApplicationPOM(String serverProjectName) {
		val applicationProjectName = getArtifactId(projectApplicationName)
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
					<artifactId>«getArtifactId(serverProjectName)»</artifactId>
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
				«buildMessagingDependency»
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
		    <artifactId>«getArtifactId(serverProjectName)»</artifactId>
		    <packaging>jar</packaging>
		    «getPOMParentSectionFull»
		    <dependencies>
		        <dependency>
		            <groupId>${project.groupId}</groupId>
		            <artifactId>«getArtifactId(clientProjectName)»</artifactId>
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
		        <dependency>
		          <groupId>com.querydsl</groupId>
		          <artifactId>querydsl-core</artifactId>
		        </dependency>
		        <dependency>
		          <groupId>com.querydsl</groupId>
		          <artifactId>querydsl-apt</artifactId>
		        </dependency>
		        <dependency>
		          <groupId>com.querydsl</groupId>
		          <artifactId>querydsl-jpa</artifactId>
		        </dependency>
		        «buildMessagingDependency»
				<!-- Begin Entity Dependencies -->
				«service?.dependencies.map[buildEntityMavenDependency]?.join»
				<!-- End Entity Dependencies -->
		    </dependencies>
		    <build>
		        <plugins>
		        	«getSourceFolderPlugin»
		        	«getMySemaMavenPlugin»
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
	
	def static getMySemaMavenPlugin() {
		'''
          <plugin>
            <groupId>com.mysema.maven</groupId>
            <artifactId>apt-maven-plugin</artifactId>
            <version>1.1.1</version>
            <executions>
              <execution>
                <goals>
                  <goal>process</goal>
                </goals>
                <configuration>
                    <outputDirectory>target/generated-sources/java</outputDirectory>
                    <processor>com.querydsl.apt.jpa.JPAAnnotationProcessor</processor>
                </configuration>
              </execution>
            </executions>
          </plugin>
		'''
	}
	
	def getPOMParentSection() {
		'''
		        <groupId>«configuration.groupId»</groupId>
		        <artifactId>«getArtifactId("parent")»</artifactId>
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
		    <artifactId>«getArtifactId(projectName)»</artifactId>
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
		    	«buildMessagingDependency»
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
			<name>«getArtifactId(projectName)»</name>
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
			<name>«getArtifactId("parent")»</name>
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
				<querydsl.version>4.2.1</querydsl.version>			
				<kerubin.messaging.version>«IF configuration.messagingVersion.isNotEmpty»«configuration.messagingVersion»«ELSE»0.0.1-SNAPSHOT«ENDIF»</kerubin.messaging.version>
				«service?.dependencies.map[buildEntityMavenDependencyVersion]?.join»			
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
					<dependency>
		               <groupId>com.querydsl</groupId>
		               <artifactId>querydsl-core</artifactId>
		               <version>${querydsl.version}</version>
		            </dependency>
					<dependency>
						<groupId>com.querydsl</groupId>
						<artifactId>querydsl-jpa</artifactId>
						<version>${querydsl.version}</version>
					</dependency>
					<dependency>
						<groupId>com.querydsl</groupId>
						<artifactId>querydsl-apt</artifactId>
						<version>${querydsl.version}</version>
					</dependency>
					<dependency>
						<groupId>org.springframework.boot</groupId>
						<artifactId>spring-boot-starter-amqp</artifactId>
					</dependency>
					<dependency>
						<groupId>com.fasterxml.jackson.core</groupId>
						<artifactId>jackson-core</artifactId>
					</dependency>
					<dependency>
						<groupId>com.fasterxml.jackson.core</groupId>
						<artifactId>jackson-annotations</artifactId>
					</dependency>
					<dependency>
						<groupId>com.fasterxml.jackson.core</groupId>
						<artifactId>jackson-databind</artifactId>
					</dependency>
					«buildMessagingDependency(true)»
					<!-- Begin Entity Dependencies -->
					«service?.dependencies.map[buildEntityMavenDependency(true)]?.join»
					<!-- End Entity Dependencies -->
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
	
	private def CharSequence buildMessagingDependency() {
		buildMessagingDependency(false)
	}
	
	private def CharSequence buildMessagingDependency(boolean withVersion) {
		'''
		<dependency>
			<groupId>br.com.kerubin.api</groupId>
			<artifactId>messaging</artifactId>
			«IF withVersion»<version>${kerubin.messaging.version}</version>«ENDIF»
		</dependency>
		'''
	}
	
	private def CharSequence buildEntityMavenDependency(MavenDependency dependency) {
		dependency.buildEntityMavenDependency(false)
	}
	
	private def CharSequence buildEntityMavenDependency(MavenDependency dependency, boolean withVersion) {
		'''
		<dependency>
			<groupId>«dependency.groupId»</groupId>
			<artifactId>«dependency.artifactId»</artifactId>
			«IF withVersion»<version>«dependency.versionFullKey»</version>«ENDIF»
		</dependency>
		'''
	}
	
	private def CharSequence buildEntityMavenDependencyVersion(MavenDependency dependency) {
		'''
		<«dependency.versionKey»>«dependency.version»</«dependency.versionKey»>
		'''
	}
	
	
}