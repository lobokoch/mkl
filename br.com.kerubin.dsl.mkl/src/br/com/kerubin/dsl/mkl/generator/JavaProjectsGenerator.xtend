package br.com.kerubin.dsl.mkl.generator

class JavaProjectsGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateJavaProjects()
	}
	
	def generateJavaProjects() {
		val PROJECT_PARENT = 'parent'
		val PROJECT_CLIENT = 'client'
		val PROJECT_SERVER = 'server'
		val MODULES_DIR = 'mod-gen/'
		val projects = #[PROJECT_CLIENT, PROJECT_SERVER]
		
		//Parent first
		generateFile(MODULES_DIR + '.project', generateJavaProject(PROJECT_PARENT))	
		generateFile(MODULES_DIR + 'pom.xml', generateParentPOM)
		
		projects.forEach[
			generateFile(MODULES_DIR + it + '/.project', generateJavaProject)	
		]
		
		generateFile(MODULES_DIR + PROJECT_CLIENT + '/pom.xml', generateClientPOM(PROJECT_CLIENT))
		generateFile(MODULES_DIR + PROJECT_SERVER + '/pom.xml', generateServerPOM(PROJECT_SERVER, PROJECT_CLIENT))
	}
	
	def generateServerPOM(String serverProjectName, String clientProjectName) {
		'''
		<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
		    xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
		    <modelVersion>4.0.0</modelVersion>
		    <artifactId>«service.name»-«serverProjectName»</artifactId>
		    <packaging>jar</packaging>
		    «getPOMParentSectionFull»
		    <dependencies>
		        <dependency>
		            <groupId>${project.groupId}</groupId>
		            <artifactId>«service.name»-«clientProjectName»</artifactId>
		            <version>${project.version}</version>
		        </dependency>
		        <dependency>
		            <groupId>org.springframework.boot</groupId>
		            <artifactId>spring-boot-starter-data-jpa</artifactId>
		        </dependency>
		        <dependency>
		            <groupId>org.postgresql</groupId>
		            <artifactId>postgresql</artifactId>
		            <scope>runtime</scope>
		        </dependency>
		        
		    </dependencies>
		</project>
		'''
	}
	
	def getPOMParentSection() {
		'''
		        <groupId>«configuration.groupId»</groupId>
		        <artifactId>«service.name»-parent</artifactId>
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
		    <artifactId>«service.name»-«projectName»</artifactId>
		    <packaging>jar</packaging>
		    «getPOMParentSectionFull»
		    <dependencies>
		    </dependencies>
		    <build>
		        <defaultGoal>install</defaultGoal>
		        <plugins>
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
			<name>«service.name»-«projectName»</name>
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
			<name>«service.name»-parent</name>
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
				<spring-cloud.version>Finchley.M9</spring-cloud.version>			
				<spring-data-releasetrain.version>Fowler-SR2</spring-data-releasetrain.version>			
			</properties>
			<modules>
				<module>client</module>
				<module>server</module>
				<module>application</module>
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
			</repositories>
			
		</project>
		'''
	}
	
	def generateParentPOM2() {
		'''
		<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
			xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
			<modelVersion>4.0.0</modelVersion>
			«getPOMParentSection»
			<packaging>pom</packaging>
			<name>«service.name»-parent</name>
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
			</properties>	
			<!--distributionManagement>
				<repository>
					<id>kerubin-release</id>
					<name>maven-releases</name>
					<url>http://maven.kerubin.com.br:8081/artifactory/libs-release-local</url>
				</repository>
				<snapshotRepository>
					<id>kerubin-snapshot</id>
					<name>maven-snapshots</name>
					<url>http://maven.kerubin.com.br:8081/artifactory/libs-snapshot-local</url>
				</snapshotRepository>
			</distributionManagement-->
			<!--repositories>
				<repository>
					<snapshots>
						<enabled>false</enabled>
					</snapshots>
					<id>central</id>
					<name>libs-release</name>
					<url>http://maven.kerubin.com.br:8081/artifactory/libs-release</url>
				</repository>
				<repository>
					<snapshots/>
						<id>snapshots</id>
						<name>libs-snapshot</name>
						<url>http://maven.kerubin.com.br:8081/artifactory/libs-snapshot</url>
				</repository>
			</repositories-->
			<build>
				<defaultGoal>install</defaultGoal>
				<plugins>
					<!-- Geração do jar dos sources -->
					<plugin>
						<groupId>org.apache.maven.plugins</groupId>
						<artifactId>maven-source-plugin</artifactId>
						<version>3.0.0</version>
						<executions>
							<execution>
								<id>attach-sources</id>
								<goals>
									<goal>jar</goal>
								</goals>
							</execution>
						</executions>
					</plugin>
				</plugins>
			</build>
		</project>
		
		'''
	}
	
}