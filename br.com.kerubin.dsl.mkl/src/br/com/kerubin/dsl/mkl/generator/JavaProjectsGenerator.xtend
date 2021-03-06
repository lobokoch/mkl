package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.MavenDependency
import br.com.kerubin.dsl.mkl.model.Service

import static br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static br.com.kerubin.dsl.mkl.generator.Utils.*

class JavaProjectsGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	static val DEFAULT_DATABASE_TYPE = 'PostgreSql'
	
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
		//val result = mountName(newArrayList(service.domain, service.name, projectApplicationName))
		val result = mountName(newArrayList(service.domain, service.name))
		result
	}
	
	def private generateApplicationProject() {
		val pomFileName = 'pom.xml'
		
		if (fsa.isFile(pomFileName, MklOutputConfigurationProvider.OUTPUT_KEEPED)) {
			//return //Already exists and must not be generated again
		}
		
		val PROJECT_SERVER = projectServerName
		val mainClassName = service.domain.textUnderToTextCamel + service.name.textUnderToTextCamel + 'Application'
		
		generateFileForApp(pomFileName, generateApplicationPOM(PROJECT_SERVER))
		generateFileForApp('Dockerfile', generateDockerfile(PROJECT_SERVER))
		
		val appSourceFolder = applicationSourceFolder
		val path = service.servicePackagePath
		generateFileForApp(appSourceFolder + path + '/' + mainClassName + '.java', generateApplicationMain(mainClassName))
		generateFileForApp(getApplicationResourcesFolder + 'bootstrap.yml', generateResourceSpringBootApplicationBootstrap())
		generateFileForApp(getApplicationResourcesFolder + 'application.yml', generateResourceSpringBootApplication())
		
		val dbMigrationPath = getApplicationResourcesFolder + 'db/migration/' + service.domain + '/' + service.name + '/' + DEFAULT_DATABASE_TYPE + '/'
		generateFileForApp(dbMigrationPath + 'V1__Creation_Tables_PostgreSQL.sql', generateResourceDBMigration)
	}
	
	def CharSequence generateDockerfile(String serverProjectName) {
		val applicationProjectName = getArtifactId(projectApplicationName)
		
		'''
		FROM openjdk:8-jdk-alpine
		VOLUME /tmp
		COPY target/*.jar «applicationProjectName».jar
		ENTRYPOINT ["java","-jar","/«applicationProjectName».jar"]
		'''
	}
	
	def CharSequence generateResourceDBMigration() {
		'''
		-- Add your «DEFAULT_DATABASE_TYPE» SQL commands here. 
		-- For example, you can copy generated tables SQL and paste here.
		'''
	}
	
	def generateResourceSpringBootApplicationBootstrap() {
		'''
		spring:
		  application:
		    name: «applicationId»
		  cloud:
		    config:
		      uri: «service.configuration.cloudConfigUri»
		
		eureka:
		  client:
		    serviceUrl:
		      defaultZone: http://localhost:8761/eureka/
		'''
	}
	
	def generateResourceSpringBootApplication() {
		'''
		server:
		  port: «configuration.servicePort»
		  
		spring:
		    rabbitmq:
		        port: 5672
		        username: admin
		        password: admin
		        host: localhost
		'''
	}
	
	def generateResourceSpringBootApplication_OLD() {
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
		val domaAndService = service.toServiceConstantsName
		
		'''
		package «service.servicePackage»;
		
		import org.springframework.boot.SpringApplication;
		import org.springframework.boot.autoconfigure.SpringBootApplication;
		import org.springframework.cloud.netflix.eureka.EnableEurekaClient;
		import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;
		import org.springframework.boot.autoconfigure.jdbc.DataSourceTransactionManagerAutoConfiguration;
		import org.springframework.boot.autoconfigure.orm.jpa.HibernateJpaAutoConfiguration;
		
		import br.com.kerubin.api.database.core.ServiceContext;
		
		@SpringBootApplication(
				exclude = { 
				        DataSourceAutoConfiguration.class,
				        HibernateJpaAutoConfiguration.class,
				        DataSourceTransactionManagerAutoConfiguration.class
				}
				, scanBasePackages = { "br.com.kerubin.api" }
		)
		@EnableEurekaClient
		public class «mainClassName» {
		
			public static void main(String[] args) {
				init();
				SpringApplication.run(«mainClassName».class, args);
			}
			
			private static void init() {
				ServiceContext.setDefaultDomain(«domaAndService».DOMAIN);
				ServiceContext.setDefaultService(«domaAndService».SERVICE);
				// ServiceConnectionProvider.INSTANCE.setMigrateDefaultTenant(true);
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
			
			<properties>
				<spring.security.oauth2>2.3.5.RELEASE</spring.security.oauth2>
				<spring.security.jwt>1.0.10.RELEASE</spring.security.jwt>
				<docker.image.prefix>lobokoch</docker.image.prefix>
				<dockerfile.maven.plugin.version>1.4.10</dockerfile.maven.plugin.version>
			</properties>
		
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
				    <groupId>org.apache.commons</groupId>
				    <artifactId>commons-lang3</artifactId>
				</dependency>
				<dependency>
					<groupId>org.springframework.boot</groupId>
					<artifactId>spring-boot-starter-test</artifactId>
					<scope>test</scope>
				</dependency>
				«buildMessagingDependency»
				
				«IF service.isEnableDoc»
				«service.generateSpringfoxSwaggerDependencies(false)»
				«ENDIF»
			</dependencies>
			
			<!-- Spring Boot package plug-in for service deploy -->
			<build>
				<finalName>${project.artifactId}-${project.version}</finalName>
				<plugins>
					<plugin>
						<groupId>org.springframework.boot</groupId>
						<artifactId>spring-boot-maven-plugin</artifactId>
						<configuration>
							<addResources>true</addResources>
						</configuration>
						<executions>
							<execution>
								<goals>
									<goal>repackage</goal>
								</goals>
							</execution>
						</executions>
					</plugin>
					<!-- For Build and Publish Docker image -->
					<!-- mvn clean package dockerfile:build -->
					<!-- mvn dockerfile:push -->
					<plugin>
						<groupId>com.spotify</groupId>
						<artifactId>dockerfile-maven-plugin</artifactId>
						<version>${dockerfile.maven.plugin.version}</version>
						<configuration>
							<repository>${docker.image.prefix}/${project.artifactId}</repository>
							<tag>${project.version}</tag>
		        			<useMavenSettingsForAuth>true</useMavenSettingsForAuth>
						</configuration>
					</plugin>
				</plugins>
			</build>
		
		
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
		        <dependency>
				    <groupId>org.apache.commons</groupId>
				    <artifactId>commons-lang3</artifactId>
				</dependency>
		        <dependency>
				    <groupId>br.com.kerubin.api</groupId>
				    <artifactId>database-core</artifactId>
				</dependency>
		        <dependency>
				    <groupId>br.com.kerubin.api</groupId>
				    <artifactId>service-core</artifactId>
				</dependency>
				<dependency>
					<groupId>org.projectlombok</groupId>
					<artifactId>lombok</artifactId>
					<scope>provided</scope>
				</dependency>
		        «buildMessagingDependency»
				<!-- Begin Entity Dependencies -->
				«service?.dependencies.map[buildEntityMavenDependency]?.join»
				<!-- End Entity Dependencies -->
				
				«IF service.isEnableDoc»
				«service.generateSpringfoxSwaggerDependencies(false)»
				«ENDIF»
				
				<dependency>
					<groupId>org.springframework.boot</groupId>
					<artifactId>spring-boot-starter-test</artifactId>
					<scope>test</scope>
				</dependency>
				
				<dependency>
					<groupId>com.h2database</groupId>
					<artifactId>h2</artifactId>
					<scope>test</scope>
				</dependency>
						
		    </dependencies>
		    <build>
		        <plugins>
		        	«IF service.canGenerateBackendTest»
		        	«generateMavenCleanPlugin»
		        	«ENDIF»
		        	«getSourceFolderPlugin»
		        	«getMySemaMavenPlugin»
		        </plugins>
		      </build>
		</project>
		'''
	}
	
	def static generateMavenCleanPlugin() {
		'''
		
		<!-- Preserves some necessary resources for tests -->
		<plugin>
			<artifactId>maven-clean-plugin</artifactId>
			<version>3.1.0</version>
			<configuration>
				<excludeDefaultDirectories>true</excludeDefaultDirectories>
				<filesets>
					<fileset>
						<directory>target</directory>
						<includes>
							<include>**</include>
						</includes>
						<excludes>
							<exclude>**/*.properties</exclude>
							<exclude>**/*.sql</exclude>
						</excludes>
					</fileset>
				</filesets>
			</configuration>
		</plugin>
		
		'''
	}
	
	def static getSourceFolderPlugin() {
		'''
          <plugin>
            <groupId>org.codehaus.mojo</groupId>
            <artifactId>build-helper-maven-plugin</artifactId>
            <version>${build.helper.maven.plugin.version}</version>
            <executions>
              
              <!-- src source folder -->
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
              
              <!-- src test source folder -->
              <execution>
                <id>add-test-source</id>
                <phase>generate-test-sources</phase>
                <goals>
                  <goal>add-test-source</goal>
                </goals>
                <configuration>
                  <sources>
                    <source>«getJavaTestSourceGen»</source>
                    <source>«getJavaTestResourceGen»</source>
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
            <version>${apt.maven.plugin.version}</version>
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
		    	<dependency>
				    <groupId>br.com.kerubin.api</groupId>
				    <artifactId>service-core</artifactId>
				</dependency>
		    	«buildMessagingDependency»
		    	<!-- End Entity Dependencies -->
		    					
				«IF service.isEnableDoc»
				«service.generateSpringfoxSwaggerDependencies(false)»
				«ENDIF»
		    </dependencies>
		    <build>
		        <defaultGoal>install</defaultGoal>
		        <plugins>
		        	«getSourceFolderPlugin»
		        	<plugin>
		        		<groupId>org.codehaus.mojo</groupId>
		        		<artifactId>templating-maven-plugin</artifactId>
		        		<version>${templating.maven.plugin.version}</version>
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
				<maven.compiler.source>«configuration.javaVersion»</maven.compiler.source>
				<maven.compiler.target>«configuration.javaVersion»</maven.compiler.target>
				<java.version>«configuration.javaVersion»</java.version>
				<project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
				<springframework.boot.version>«configuration.springFrameworkBootVersion»</springframework.boot.version>
				<spring-cloud.version>«configuration.springCloudVersion»</spring-cloud.version>
				<spring-data-releasetrain.version>«configuration.springDataReleasetrainVersion»</spring-data-releasetrain.version>
				<querydsl.version>«configuration.queryDSLVersion»</querydsl.version>
				<commons.lang.version>«configuration.apacheCommonsLangVersion»</commons.lang.version>
				<database.core.version>«configuration.databaseCoreVersion»</database.core.version>
				<service.core.version>«configuration.serviceCoreVersion»</service.core.version>
				<flyway.core.version>«configuration.flywayCoreVersion»</flyway.core.version>
				<kerubin.messaging.core.version>«configuration.messagingCoreVersion»</kerubin.messaging.core.version>
				<build.helper.maven.plugin.version>«configuration.buildHelperMavenPluginVersion»</build.helper.maven.plugin.version>
				<apt.maven.plugin.version>«configuration.aptMavenPluginVersion»</apt.maven.plugin.version>
				<templating.maven.plugin.version>«configuration.templatingMavenPluginVersion»</templating.maven.plugin.version>
				«service?.dependencies.map[buildEntityMavenDependencyVersion]?.join»
				«IF service.isEnableDoc»
				<springfox.swagger2.version>«service.configuration.springfoxSwaggerVersion»</springfox.swagger2.version>
				«ENDIF»
			</properties>
			<modules>
				<module>«projectClientName»</module>
				<module>«projectServerName»</module>
				<module>«projectApplicationName»</module>
			</modules>
			<dependencyManagement>
				<dependencies>
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
					<dependency>
					    <groupId>org.apache.commons</groupId>
					    <artifactId>commons-lang3</artifactId>
					    <version>${commons.lang.version}</version>
					</dependency>
					<dependency>
						<groupId>org.flywaydb</groupId>
						<artifactId>flyway-core</artifactId>
						<version>${flyway.core.version}</version>
					</dependency>
					<dependency>
						<groupId>br.com.kerubin.api</groupId>
						<artifactId>database-core</artifactId>
						<version>${database.core.version}</version>
					</dependency>
					<dependency>
						<groupId>br.com.kerubin.api</groupId>
						<artifactId>service-core</artifactId>
						<version>${service.core.version}</version>
					</dependency>
					
					«buildMessagingDependency(true)»
					<!-- Begin Entity Dependencies -->
					«service?.dependencies.map[buildEntityMavenDependency(true)]?.join»
					<!-- End Entity Dependencies -->
					
					«IF service.isEnableDoc»
					«service.generateSpringfoxSwaggerDependencies(true)»
					«ENDIF»
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
	
	private def CharSequence generateSpringfoxSwaggerDependencies(Service service, boolean withVersion) {
		'''
		<!-- Begin Springfox Swagger2 dependencies -->
		<dependency>
			<groupId>io.springfox</groupId>
			<artifactId>springfox-swagger2</artifactId>
			«IF withVersion»
			<version>${springfox.swagger2.version}</version>
			<exclusions>
				<exclusion>
					<groupId>io.swagger</groupId>
					<artifactId>swagger-annotations</artifactId>
				</exclusion>
				<exclusion>
					<groupId>io.swagger</groupId>
					<artifactId>swagger-models</artifactId>
				</exclusion>
			</exclusions>
			«ENDIF»
		</dependency>
		<dependency>
			<groupId>io.springfox</groupId>
			<artifactId>springfox-swagger-ui</artifactId>
			«IF withVersion»<version>${springfox.swagger2.version}</version>«ENDIF»
		</dependency>
		<dependency>
			<groupId>io.springfox</groupId>
			<artifactId>springfox-data-rest</artifactId>
			«IF withVersion»<version>${springfox.swagger2.version}</version>«ENDIF»
		</dependency>
		<dependency>
			<groupId>io.springfox</groupId>
			<artifactId>springfox-bean-validators</artifactId>
			«IF withVersion»<version>${springfox.swagger2.version}</version>«ENDIF»
		</dependency>
		
		<!-- Begin fix issue: https://github.com/springfox/springfox/issues/2265 -->
		<dependency>
			<groupId>io.swagger</groupId>
			<artifactId>swagger-annotations</artifactId>
			«IF withVersion»<version>1.5.21</version>«ENDIF»
		</dependency>
		<dependency>
			<groupId>io.swagger</groupId>
			<artifactId>swagger-models</artifactId>
			«IF withVersion»<version>1.5.21</version>«ENDIF»
		</dependency>
		<!-- End fix issue: https://github.com/springfox/springfox/issues/2265 -->
		
		<!-- End Springfox Swagger2 dependencies -->
		'''
	}
	
	private def CharSequence buildMessagingDependency() {
		buildMessagingDependency(false)
	}
	
	private def CharSequence buildMessagingDependency(boolean withVersion) {
		'''
		<dependency>
			<groupId>br.com.kerubin.api</groupId>
			<artifactId>messaging-core</artifactId>
			«IF withVersion»<version>${kerubin.messaging.core.version}</version>«ENDIF»
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