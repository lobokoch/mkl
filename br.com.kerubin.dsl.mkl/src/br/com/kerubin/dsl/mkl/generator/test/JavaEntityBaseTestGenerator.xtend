package br.com.kerubin.dsl.mkl.generator.test

import br.com.kerubin.dsl.mkl.generator.BaseGenerator
import br.com.kerubin.dsl.mkl.generator.GeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.IGeneratorExecutor

import static br.com.kerubin.dsl.mkl.generator.Utils.*
import static extension br.com.kerubin.dsl.mkl.generator.test.TestUtils.*
import java.util.Set

class JavaEntityBaseTestGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	var Set<String> imports = newLinkedHashSet
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		generateTestApplication
	}
	
	def generateTestApplication() {
		val basePakage = getServerTestGenSourceFolder
		val fileName = basePakage + service.servicePackagePath + '/' + service.toServiceEntityBaseTestClassName + '.java'
		generateFile(fileName, doGenerateBaseTest)
	}
	
	def CharSequence doGenerateBaseTest() {
		
		imports.add('import java.time.LocalDate;')
		imports.add('import java.util.List;')
		imports.add('import java.util.ArrayList;')
		imports.add('import java.util.Collections;')
		imports.add('import java.util.Random;')
		imports.add('import org.apache.commons.lang3.RandomStringUtils;')
		
		imports.add('import javax.inject.Inject;')
		imports.add('import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;')
		
		val package = '''
		package «service.servicePackage»;
		
		'''
		
		val body = '''
		
		«imports.generateTestAnnotations»
		public class «service.toServiceEntityBaseTestClassName» {
			«IF service.isEnableCustomTestConfig»
			
			private static TestVisitor customTestVisitor;
			«ENDIF»
			«generateFieldLastDate»
			
			@Inject
			protected TestEntityManager em;
			
			«imports.generateTestConfiguration»
			«service.generateTestVisitorInjectAndSet»
			«generateMethodGetNextDate»
			
			«generateMethodResetNextDate»
			
			«generateMethodGenerateRandomString»
			
			«generateMethodGetRandomItemsOf»
			
			«IF service.isEnableCustomTestConfig»
						
			public TestEntityManager getEm() {
				return em;
			}
			«ENDIF»
		
		}
		'''
		
		val importsContent = '''
		«imports.map[it].join('\r\n')»
		
		'''
		
		package + importsContent + body
		
	}
	
	def CharSequence generateTestAnnotations(Set<String> imports) {
		
		imports.add('import org.springframework.test.context.TestPropertySource;')
		imports.add('import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;')
		imports.add('import org.springframework.data.jpa.repository.config.EnableJpaAuditing;')
		
		'''
		@TestPropertySource(locations = "classpath:default-test.properties")
		@DataJpaTest
		@EnableJpaAuditing(auditorAwareRef="auditorAware")
		«IF service.isEnableCustomTestConfig»
		// A class with name CustomTestConfig must be manually created by the user.
		@Import(CustomTestConfig.class)
		«ENDIF»
		'''
		
	}
	
	def CharSequence generateTestConfiguration(Set<String> imports) {
		imports.add('import org.springframework.boot.test.context.TestConfiguration;')
		imports.add('import org.springframework.data.domain.AuditorAware;')
		imports.add('import br.com.kerubin.api.database.entity.AuditorAwareImpl;')
		imports.add('import org.springframework.context.annotation.Bean;')
		
		if (service.isEnableCustomTestConfig) {
			imports.add('import org.springframework.context.annotation.Import;')
			imports.add('import javax.inject.Inject;')
		}
		
		'''
		// BEGIN base configurations
		@TestConfiguration
		static class «service.toServiceEntityBaseTestConfigClassName» {
			
			@Bean
			public AuditorAware<String> auditorAware() {
				return new AuditorAwareImpl();
			}
			
			@Bean
			public br.com.kerubin.api.servicecore.mapper.ObjectMapper objectMapper() {
				return new br.com.kerubin.api.servicecore.mapper.ObjectMapper();
			}
			«IF service.isEnableCustomTestConfig»
			
			@Bean
			public «service.toServiceTestVisitorInterfaceClassName» testVisitor() {
				if (customTestVisitor != null) {
					return customTestVisitor;
				}
				
				return new «service.toServiceTestVisitorInterfaceDafaultImplClassName»();
			}
			«ENDIF»
		}
		// END base configurations
		
		'''
	}
	
			
}