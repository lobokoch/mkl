package br.com.kerubin.dsl.mkl.generator

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.Utils.*
import br.com.kerubin.dsl.mkl.model.Entity

class WebNavbarComponentHTMLGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		generateComponent
	}
	
	protected def String getWebNavbarFileDir() {
		getWebNavbarDir()
	}
	
	protected def getFileExtension() {
		'.html'
	}
	
	def generateComponent() {
		val path = getWebNavbarFileDir()
		val filePath = path + toWebNavbarComponentName + getFileExtension()
		generateFile(filePath, doGenerateComponent)
	}
	
	protected def CharSequence doGenerateComponent() {
		'''
		<nav class="navbar">
		  <div class="container">
		    <div class="ui-g">
		      <div class="i-g-12">
		        <a href="javascript:;" class="navbar-toggle" (click)="isMenuShowing = !isMenuShowing"><i class="pi pi-bars"></i></a>
		      </div>
		
		    </div>
		  </div>
		
		  <ul class="navbar-menu" [hidden]="!isMenuShowing">
		    <li class="navbar-user">Kerubin User</li>
		    
		    <!-- Begin Menu Items -->
		    «generateMenuItems»
		    <!-- End Menu Items -->
		    
		    <li class="navbar-menuitem"><a href="javascript:;">Logout</a></li>
		  </ul>
		
		</nav>
		'''
	}
	
	/*protected def CharSequence generateMenuItems() {
		'''
		Copy your menu items heare.
		'''
	}*/
	
	// PROVISÓRIO PARA NÃO PRECISAR COPIAR E COLAR DURANTE OS TESTES.
	protected def CharSequence generateMenuItems() {
		'''
		<!-- Begin «service.domain».«service.name» menu itens -->
		«generateEntitiesMenuItems»
		<!-- End «service.domain».«service.name» menu itens -->
		
		'''
	}
	
	private def CharSequence generateEntitiesMenuItems() {
		'''
		«entities.map[generateEntityMenuItem].join»
		'''
	}
	
	private def CharSequence generateEntityMenuItem(Entity entity) {
		'''
		<li class="navbar-menuitem" routerLinkActive="active"><a routerLink="/«entity.toWebName»">«entity.labelValue»</a></li>
		'''
	}
	
	
}