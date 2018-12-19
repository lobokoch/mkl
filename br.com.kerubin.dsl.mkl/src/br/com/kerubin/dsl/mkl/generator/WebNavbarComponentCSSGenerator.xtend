package br.com.kerubin.dsl.mkl.generator

class WebNavbarComponentCSSGenerator extends WebNavbarComponentHTMLGenerator {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override getFileExtension() {
		'.css'
	}	
	
	override doGenerateComponent() {
		'''
		.navbar {
		  padding: 10px 0;
		  background-color: #1e94d2;
		}
		
		.navbar-toggle {
		  color: #fff;
		}
		
		.navbar-menu {
		  position: fixed;
		  top: 0px;
		  bottom: 0px;
		  right: 0px;
		  width: 210px;
		  margin: 0px;
		  background-color: #3a3633;
		  z-index: 9999;
		  padding: 0px;
		  list-style: none;
		}
		
		.navbar-user {
		  color: #fff;
		  font-weight: bold;
		  text-transform: uppercase;
		  padding: 15px;
		  border-bottom: 1px solid#525151;
		  margin-bottom: 15px;
		}
		
		.navbar-menuitem {
		  padding: 15px;
		}
		
		.navbar-menuitem a {
		  color: #c0bbb7;
		  text-decoration: none;
		}
		
		.navbar-menuitem a:hover {
		  color: #fff;
		}
		
		.navbar-menuitem.active {
		  background-color: #494541;
		}
		
		.navbar-footer {
		  bottom: 0px;
		  height: 100px;
		}
		
		
		'''
	}
	
}